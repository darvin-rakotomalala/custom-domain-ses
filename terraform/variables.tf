#########################################################
# MAIN VARIABLES
#########################################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "owner" {
  type        = string
  description = "The owner or team responsible for this resource."
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

# ---- SES ----------------------------------------------------------------------------------------------
variable "domain_name" {
  description = "Verified SES domain identity (registered and hosted in Route 53)."
  type        = string
}

variable "from_subdomain" {
  description = "Visible From domain = <from_subdomain>.<domain_name>."
  type        = string
}

variable "from_local_part" {
  type        = string
  description = "The local part (the username portion before the '@' symbol) of the sender email address."
}

variable "mail_from_subdomain" {
  description = "Dedicated MAIL FROM subdomain (not used for anything else)."
  type        = string
}

variable "behavior_on_mx_failure" {
  type        = string
  description = "The action to take when mail exchange (MX) record lookup fails (e.g., 'REJECT_MESSAGE' or 'ALLOW_MESSAGE')."
}

variable "recipient_email" {
  description = "Site owner mailbox that receives contact-form messages."
  type        = string
}

variable "verify_recipient_identity" {
  description = "Create an SES identity for the recipient (needed while the SES account is in the sandbox)."
  type        = bool
}

variable "dmarc_policy" {
  type        = string
  description = "The DMARC policy for emails that fail authentication (e.g., 'none', 'quarantine', or 'reject')."
}

variable "dmarc_report_email" {
  type        = string
  description = "The email address where aggregate (RUA) and forensic (RUF) DMARC reports should be sent."
}

variable "create_dmarc_record" {
  type        = bool
  description = "Whether to create the DNS DMARC record automatically."
}

variable "from_address" {
  type        = string
  description = "Visible From address (on the verified domain), e.g. no-reply@cloudwithdarvin.com."
}

variable "dns_ttl" {
  type        = number
  description = "The Time To Live (TTL) value in seconds for DNS records."
}

variable "deletion_window_in_days" {
  type        = number
  description = "The waiting period, specified in number of days, before KMS deletes the key after it is destroyed."
}

# ---- Lambda -------------------------------------------------------------------------------------------
variable "lambda_function_name" {
  type        = string
  description = "The name of the AWS Lambda function."
}

variable "lambda_description" {
  description = "The description of the Lambda function."
  type        = string
}

variable "lambda_log_group_name" {
  type        = string
  description = "The name of the CloudWatch log group associated with the Lambda function."
}

variable "lambda_handler" {
  type        = string
  description = "The function entrypoint in your code that Lambda calls to begin execution."
}

variable "lambda_role_name" {
  type        = string
  description = "The name of the IAM role."
}

variable "lambda_memory_size" {
  type        = number
  description = "The amount of memory in MB allocated to the Lambda function."
}

variable "lambda_reserved_concurrency" {
  description = "-1 = unreserved. Set a cap (e.g. 20) to protect SES quota/cost; needs enough unreserved account concurrency."
  type        = number
}

variable "lambda_provisioned_concurrency" {
  description = "0 = rely on SnapStart only."
  type        = number
}

variable "runtime" {
  description = "The identifier of the function's runtime environment."
  type        = string
}

variable "architecture" {
  description = "Instruction set architecture for your Lambda function. x86_64 or arm64. Check current SnapStart support for arm64 before switching."
  type        = string
}

variable "lambda_timeout" {
  description = "The amount of time, in seconds, that Lambda allows a function to run before stopping it. API Gateway's integration limit is 29s, so never go above that."
  type        = number

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 29
    error_message = "Timeout must be between 1 and 29 seconds."
  }
}

variable "alias_name" {
  description = "The name of the Lambda function alias."
  type        = string
}

# ---- API Gateway --------------------------------------------------------------------------------------
variable "api_name" {
  type        = string
  description = "The name of the API."
}

variable "stage_name" {
  description = "The name of the API Gateway stage (e.g., prod, dev, staging)."
  type        = string
}

variable "api_log_group_name" {
  type        = string
  description = "The name of the CloudWatch log group for the API."
}

/*
variable "cors_allowed_origins" {
  description = "Browser origins allowed to call the API. The first entry is also used on gateway-generated errors."
  type        = list(string)

  validation {
    condition     = length(var.cors_allowed_origins) > 0 && !contains(var.cors_allowed_origins, "*")
    error_message = "Provide at least one explicit origin; wildcard '*' is not allowed."
  }
}
*/

variable "cors_allowed_origin" {
  type        = string
  description = "Single origin (or *) returned on gateway-generated 4xx/5xx responses."

  validation {
    condition     = var.cors_allowed_origin == "*" || can(regex("^https?://[^/,*]+$", var.cors_allowed_origin))
    error_message = "Must be '*' or a single origin like https://example.com (no trailing slash, commas, or wildcards)."
  }
}

variable "stage_throttling_rate_limit" {
  description = "Steady-state requests/second for the whole stage."
  type        = number
}

variable "stage_throttling_burst_limit" {
  description = "Burst requests limit for the whole stage."
  type        = number
}

variable "enable_method_throttling" {
  description = "Whether to enable fine-grained method-level throttling settings."
  type        = bool
}

variable "method_throttling_rate_limit" {
  description = "Steady-state requests/second limit for specific API methods."
  type        = number
}

variable "method_throttling_burst_limit" {
  description = "Burst requests limit for specific API methods."
  type        = number
}

variable "manage_account_settings" {
  description = "Create the account-level CloudWatch role for API Gateway. Set false if it is already configured in this region."
  type        = bool
}

variable "cloudwatch_role_name" {
  description = "The name of the IAM role used by API Gateway to push logs to CloudWatch."
  type        = string
}

variable "api_stage_rate_limit" {
  type        = number
  description = "The steady-state rate limit (requests per second) allowed for the API stage."
}

variable "api_stage_burst_limit" {
  type        = number
  description = "The maximum burst limit (concurrent requests capacity) allowed for the API stage."
}

variable "api_method_rate_limit" {
  type        = number
  description = "The steady-state rate limit (requests per second) allowed for specific API methods."
}

variable "api_method_burst_limit" {
  type        = number
  description = "The maximum burst limit (concurrent requests capacity) allowed for specific API methods."
}

variable "manage_api_gateway_account" {
  description = "Create the account-level API Gateway CloudWatch role (set false if already configured in this region)."
  type        = bool
}

variable "enable_waf" {
  description = "Attach an AWS WAF web ACL (rate limit + managed reputation rules). Adds ~USD 8/month fixed cost."
  type        = bool
}

variable "rate_limit_per_ip" {
  description = "Max requests per IP per 5 minutes before WAF blocks (minimum 10)."
  type        = number
}

# ---- Observability --------------------------------------------------------------------------------------

variable "alert_emails" {
  type        = list(string)
  description = "Addresses subscribed to both alert topics (each must confirm the subscription)."
}

variable "critical_https_endpoint" {
  description = "PagerDuty/OpsGenie HTTPS endpoint for critical alarms (optional)."
  type        = string
}

variable "log_retention_days" {
  type        = number
  description = "The number of days to retain log events in the specified log group."
}

variable "lambda_concurrency_alarm_threshold" {
  type        = number
  description = "Alarm when account-wide concurrent executions reach this value (default account limit is 1000)."
}

variable "api_5xx_threshold_per_minute" {
  type        = number
  description = "The threshold for API Gateway 5xx errors per minute before triggering an alarm."
}

variable "api_4xx_threshold_per_5min" {
  type        = number
  description = "The threshold for API Gateway 4xx errors per 5 minutes before triggering an alarm."
}

variable "api_latency_threshold_ms" {
  type        = number
  description = "The API Gateway latency threshold in milliseconds before triggering an alarm."
}

variable "api_integration_latency_threshold_ms" {
  type        = number
  description = "The API Gateway integration latency threshold in milliseconds before triggering an alarm."
}
