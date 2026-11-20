###########################################
## API GATEWAY
###########################################

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "Contact-form REST API (Lambda proxy integration)"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE" # public contact form; protected by throttling, WAF (optional), CORS and validation

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integration targets the ALIAS invoke ARN so SnapStart-enabled published versions are used.
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_alias_invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  qualifier     = var.lambda_alias_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# Gateway-generated errors (429 throttling, 403 WAF, 5xx) never reach Spring, so add CORS headers here
# or the browser would hide the real status code from the front end.
resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'${var.cors_allowed_origin}'"
    "gatewayresponse.header.Vary"                        = "'Origin'"
  }
}

resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'${var.cors_allowed_origin}'"
    "gatewayresponse.header.Vary"                        = "'Origin'"
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # New deployment on every API change.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.lambda.id,
      aws_api_gateway_integration.lambda.uri,
      aws_api_gateway_gateway_response.default_4xx.response_parameters,
      aws_api_gateway_gateway_response.default_5xx.response_parameters,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---- Account-level role so API Gateway can write access logs (one per region/account) ---------

data "aws_iam_policy_document" "apigw_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_cloudwatch" {
  count              = var.manage_account_settings ? 1 : 0
  name               = var.cloudwatch_role_name
  assume_role_policy = data.aws_iam_policy_document.apigw_assume.json
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch" {
  count      = var.manage_account_settings ? 1 : 0
  role       = aws_iam_role.apigw_cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  count               = var.manage_account_settings ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch[0].arn
  depends_on          = [aws_iam_role_policy_attachment.apigw_cloudwatch]
}

# ---- Stage --------------------------------------------------------------------------------------

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = var.access_log_group_arn

    # status/latency fields are unquoted numbers so Logs Insights and metric filters can compare them.
    # integrationLatency is quoted because API Gateway emits "-" when no integration ran (e.g. throttled).
    format = "{\"requestId\":\"$context.requestId\",\"ip\":\"$context.identity.sourceIp\",\"requestTime\":\"$context.requestTime\",\"httpMethod\":\"$context.httpMethod\",\"path\":\"$context.path\",\"resourcePath\":\"$context.resourcePath\",\"status\":$context.status,\"protocol\":\"$context.protocol\",\"responseLength\":$context.responseLength,\"responseLatency\":$context.responseLatency,\"integrationLatency\":\"$context.integrationLatency\",\"integrationStatus\":\"$context.integrationStatus\",\"errorMessage\":\"$context.error.message\",\"userAgent\":\"$context.identity.userAgent\"}"
  }

  depends_on = [aws_api_gateway_account.this]
}

# Stage-level defaults + detailed metrics. Execution logging is OFF on purpose: it writes to an
# AWS-managed, non-KMS log group and can include request bodies (visitor PII).
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "OFF"
    data_trace_enabled     = false
    caching_enabled        = false
    throttling_rate_limit  = var.stage_throttling_rate_limit
    throttling_burst_limit = var.stage_throttling_burst_limit
  }
}

# Method-level (stricter) limits for the contact endpoint, so a burst cannot exhaust Lambda concurrency.
resource "aws_api_gateway_method_settings" "proxy" {
  count       = var.enable_method_throttling ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "OFF"
    data_trace_enabled     = false
    caching_enabled        = false
    throttling_rate_limit  = var.method_throttling_rate_limit
    throttling_burst_limit = var.method_throttling_burst_limit
  }

  depends_on = [aws_api_gateway_method_settings.all]
}
