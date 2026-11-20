###########################################
## LAMBDA
###########################################

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = var.role_arn

  runtime       = var.runtime
  handler       = var.handler
  architectures = [var.architecture]
  memory_size   = var.memory_size
  timeout       = var.timeout

  # Point directly to your compiled application zip file
  filename         = "${path.module}/ses-contact-form.zip"
  source_code_hash = filebase64sha256("${path.module}/ses-contact-form.zip")

  # SnapStart only applies to PUBLISHED versions, so every change publishes a new one.
  publish = true

  # -1 = no reservation. A reservation caps concurrency (protects SES quota and cost) but needs
  # enough unreserved account concurrency (AWS keeps a minimum of 100 unreserved).
  reserved_concurrent_executions = var.reserved_concurrency

  snap_start {
    apply_on = "PublishedVersions"
  }

  logging_config {
    log_format = "Text"
    log_group  = var.log_group_name
  }

  environment {
    variables = var.environment_variables
  }

}

# API Gateway must invoke the alias (not $LATEST), otherwise SnapStart does not apply.
resource "aws_lambda_alias" "this" {
  name             = var.alias_name
  description      = "Points to the latest published (SnapStart) version"
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}

# Optional: keep N execution environments warm on the alias, on top of SnapStart.
resource "aws_lambda_provisioned_concurrency_config" "this" {
  count                             = var.provisioned_concurrency > 0 ? 1 : 0
  function_name                     = aws_lambda_function.this.function_name
  qualifier                         = aws_lambda_alias.this.name
  provisioned_concurrent_executions = var.provisioned_concurrency
}
