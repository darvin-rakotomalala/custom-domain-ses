###########################################
## MONITORING
###########################################

locals {
  metric_namespace = "${var.project}/${var.environment}"
  lambda_dims      = { FunctionName = var.lambda_function_name }
  api_dims         = { ApiName = var.api_name, Stage = var.api_stage_name }
}

# ---- Log groups (KMS-encrypted, explicit retention) ------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  name              = var.lambda_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_cloudwatch_log_group" "api" {
  name              = var.api_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

# ---- SNS alert topics (KMS-encrypted) ----------------------------------------------------------------

resource "aws_sns_topic" "critical" {
  name              = "${var.project}-${var.environment}-alerts-critical"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sns_topic" "warning" {
  name              = "${var.project}-${var.environment}-alerts-warning"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sns_topic_subscription" "critical_email" {
  for_each  = toset(var.alert_emails)
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "warning_email" {
  for_each  = toset(var.alert_emails)
  topic_arn = aws_sns_topic.warning.arn
  protocol  = "email"
  endpoint  = each.value
}

# PagerDuty / OpsGenie "CloudWatch" integration URL (https) for critical pages.
resource "aws_sns_topic_subscription" "critical_pager" {
  count     = var.critical_https_endpoint == "" ? 0 : 1
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "https"
  endpoint  = var.critical_https_endpoint
}

# ---- Lambda metric filters ----------------------------------------------------------------------------
# NOTE: Lambda log format is "Text", so these are plain-text patterns. Under SnapStart the REPORT line
# contains "Restore Duration" instead of "Init Duration", hence both are matched for cold-start tracking.

locals {
  lambda_filters = {
    LambdaTimeouts = {
      pattern = "\"Task timed out after\""
    }
    LambdaOutOfMemory = {
      pattern = "?\"OutOfMemoryError\" ?\"Runtime.OutOfMemory\" ?\"signal: killed\""
    }
    UnhandledErrors = {
      pattern = "?\"ERROR\" ?\"Error\" ?\"Exception\" ?\"Unhandled\" ?\"panic\""
    }
    ColdStarts = {
      pattern = "?\"Init Duration\" ?\"Restore Duration\""
    }
    ErrorLogCount = {
      pattern = "\"ERROR\""
    }
    WarnLogCount = {
      pattern = "\"WARN\""
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "lambda" {
  for_each       = local.lambda_filters
  name           = each.key
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = each.value.pattern

  metric_transformation {
    name          = each.key
    namespace     = "${local.metric_namespace}/Lambda"
    value         = "1"
    default_value = "0"
  }
}

# API Gateway REST APIs emit no dedicated throttle metric (429s fold into 4XXError), so derive one from access logs.
resource "aws_cloudwatch_log_metric_filter" "api_throttled" {
  name           = "ApiThrottled"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "{ $.status = 429 }"

  metric_transformation {
    name          = "ApiThrottled"
    namespace     = "${local.metric_namespace}/ApiGateway"
    value         = "1"
    default_value = "0"
  }
}

# ---- Alarms (data-driven; severity selects the SNS topic) ---------------------------------------------

locals {
  alarms = {
    # ---------------- Lambda ----------------
    lambda-errors = {
      description        = "Lambda invocations are failing."
      namespace          = "AWS/Lambda"
      metric_name        = "Errors"
      dimensions         = local.lambda_dims
      statistic          = "Sum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = 1
      severity           = "critical"
    }
    lambda-throttles = {
      description        = "Lambda is being throttled (concurrency limit reached)."
      namespace          = "AWS/Lambda"
      metric_name        = "Throttles"
      dimensions         = local.lambda_dims
      statistic          = "Sum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = 1
      severity           = "warning"
    }
    lambda-duration-p95 = {
      description        = "p95 duration is above 80% of the function timeout: bottleneck or imminent timeouts."
      namespace          = "AWS/Lambda"
      metric_name        = "Duration"
      dimensions         = local.lambda_dims
      statistic          = null
      extended_statistic = "p95"
      period             = 300
      evaluation_periods = 2
      threshold          = var.lambda_timeout_seconds * 1000 * 0.8
      severity           = "warning"
    }
    lambda-account-concurrency = {
      description        = "Account-wide Lambda concurrent executions are approaching the account limit."
      namespace          = "AWS/Lambda"
      metric_name        = "ConcurrentExecutions"
      dimensions         = {}
      statistic          = "Maximum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = var.lambda_concurrency_alarm_threshold
      severity           = "warning"
    }
    lambda-timeouts = {
      description        = "Log filter detected 'Task timed out'."
      namespace          = "${local.metric_namespace}/Lambda"
      metric_name        = "LambdaTimeouts"
      dimensions         = {}
      statistic          = "Sum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = 1
      severity           = "critical"
    }
    lambda-out-of-memory = {
      description        = "Log filter detected an out-of-memory condition; raise memory_size."
      namespace          = "${local.metric_namespace}/Lambda"
      metric_name        = "LambdaOutOfMemory"
      dimensions         = {}
      statistic          = "Sum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = 1
      severity           = "critical"
    }
    lambda-unhandled-errors = {
      description        = "Unhandled exceptions or runtime crashes found in the application log."
      namespace          = "${local.metric_namespace}/Lambda"
      metric_name        = "UnhandledErrors"
      dimensions         = {}
      statistic          = "Sum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = 1
      severity           = "critical"
    }
    # ---------------- API Gateway ----------------
    api-5xx = {
      description        = "High 5xx error rate (errors per minute)."
      namespace          = "AWS/ApiGateway"
      metric_name        = "5XXError"
      dimensions         = local.api_dims
      statistic          = "Sum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = var.api_5xx_threshold_per_minute
      severity           = "critical"
    }
    api-4xx = {
      description        = "Spike in 4xx errors (bad payloads, CORS, abuse)."
      namespace          = "AWS/ApiGateway"
      metric_name        = "4XXError"
      dimensions         = local.api_dims
      statistic          = "Sum"
      extended_statistic = null
      period             = 300
      evaluation_periods = 1
      threshold          = var.api_4xx_threshold_per_5min
      severity           = "warning"
    }
    api-latency-p95 = {
      description        = "High overall API latency."
      namespace          = "AWS/ApiGateway"
      metric_name        = "Latency"
      dimensions         = local.api_dims
      statistic          = null
      extended_statistic = "p95"
      period             = 300
      evaluation_periods = 2
      threshold          = var.api_latency_threshold_ms
      severity           = "warning"
    }
    api-integration-latency-p95 = {
      description        = "High integration latency: backend (Lambda/SES) dependency issue."
      namespace          = "AWS/ApiGateway"
      metric_name        = "IntegrationLatency"
      dimensions         = local.api_dims
      statistic          = null
      extended_statistic = "p95"
      period             = 300
      evaluation_periods = 2
      threshold          = var.api_integration_latency_threshold_ms
      severity           = "warning"
    }
    api-throttled = {
      description        = "API Gateway is returning 429 (rate/burst limits reached)."
      namespace          = "${local.metric_namespace}/ApiGateway"
      metric_name        = "ApiThrottled"
      dimensions         = {}
      statistic          = "Sum"
      extended_statistic = null
      period             = 60
      evaluation_periods = 1
      threshold          = 1
      severity           = "warning"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${var.project}-${var.environment}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  dimensions          = each.value.dimensions
  statistic           = each.value.statistic
  extended_statistic  = each.value.extended_statistic
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [each.value.severity == "critical" ? aws_sns_topic.critical.arn : aws_sns_topic.warning.arn]
  ok_actions    = [each.value.severity == "critical" ? aws_sns_topic.critical.arn : aws_sns_topic.warning.arn]
}

# ---- Logs Insights saved queries ----------------------------------------------------------------------

resource "aws_cloudwatch_query_definition" "api_errors_by_path" {
  name            = "${var.project}/${var.environment}/api-4xx-5xx-by-path"
  log_group_names = [aws_cloudwatch_log_group.api.name]

  query_string = <<-EOT
    fields @timestamp, httpMethod, path, status
    | filter status >= 400
    | stats count(*) as errors by path, status
    | sort errors desc
  EOT
}

resource "aws_cloudwatch_query_definition" "api_slow_requests" {
  name            = "${var.project}/${var.environment}/api-slow-requests"
  log_group_names = [aws_cloudwatch_log_group.api.name]

  query_string = <<-EOT
    fields @timestamp, httpMethod, path, status, responseLatency, integrationLatency
    | filter responseLatency > ${var.api_integration_latency_threshold_ms}
    | sort responseLatency desc
    | limit 50
  EOT
}

# ---- Dashboard ------------------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.project}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Lambda invocations / errors / throttles"
          region = var.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
            [".", "Errors", ".", "."],
            [".", "Throttles", ".", "."],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Lambda duration (p50 / p95 / max)"
          region = var.region
          period = 60
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name, { stat = "p50" }],
            ["...", { stat = "p95" }],
            ["...", { stat = "Maximum" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "API requests / 4xx / 5xx"
          region = var.region
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", var.api_name, "Stage", var.api_stage_name],
            [".", "4XXError", ".", ".", ".", "."],
            [".", "5XXError", ".", ".", ".", "."],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "API latency vs integration latency (p95)"
          region = var.region
          period = 60
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_name, "Stage", var.api_stage_name, { stat = "p95" }],
            [".", "IntegrationLatency", ".", ".", ".", ".", { stat = "p95" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title  = "Cold starts / ERROR / WARN log lines"
          region = var.region
          stat   = "Sum"
          period = 300
          metrics = [
            ["${local.metric_namespace}/Lambda", "ColdStarts"],
            [".", "ErrorLogCount"],
            [".", "WarnLogCount"],
          ]
        }
      },
    ]
  })
}
