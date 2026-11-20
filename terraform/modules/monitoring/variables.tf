###########################################
## MONITORING VARIABLES
###########################################

variable "project" {
  type        = string
  description = "The name of the project associated with the resource."
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g., dev, staging, prod)."
}

variable "region" {
  type        = string
  description = "The AWS region where resources will be deployed."
}

variable "kms_key_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the KMS key."
}

variable "lambda_function_name" {
  type        = string
  description = "The name of the Lambda function."
}

variable "lambda_log_group_name" {
  type        = string
  description = "The name of the CloudWatch log group for the Lambda function."
}

variable "lambda_timeout_seconds" {
  type        = number
  description = "The amount of time Lambda allows a function to run before stopping it, in seconds."
}

variable "api_name" {
  type        = string
  description = "The name of the API Gateway API."
}

variable "api_stage_name" {
  type        = string
  description = "The deployment stage name for the API Gateway API."
}

variable "api_log_group_name" {
  type        = string
  description = "The name of the CloudWatch log group for API Gateway."
}

variable "log_retention_days" {
  type        = number
  default     = 90
  description = "The number of days to retain log events in the specified log group."
}

variable "alert_emails" {
  type        = list(string)
  default     = []
  description = "Addresses subscribed to both alert topics (each must confirm the subscription)."
}

variable "critical_https_endpoint" {
  type        = string
  default     = ""
  description = "PagerDuty/OpsGenie HTTPS integration URL for critical alarms. Empty = none."
}

variable "lambda_concurrency_alarm_threshold" {
  type        = number
  default     = 800
  description = "Alarm when account-wide concurrent executions reach this value (default account limit is 1000)."
}

variable "api_5xx_threshold_per_minute" {
  type        = number
  default     = 3
  description = "The threshold for API Gateway 5xx errors per minute before triggering an alarm."
}

variable "api_4xx_threshold_per_5min" {
  type        = number
  default     = 25
  description = "The threshold for API Gateway 4xx errors per 5 minutes before triggering an alarm."
}

variable "api_latency_threshold_ms" {
  type        = number
  default     = 5000
  description = "The API Gateway latency threshold in milliseconds before triggering an alarm."
}

variable "api_integration_latency_threshold_ms" {
  type        = number
  default     = 4000
  description = "The API Gateway integration latency threshold in milliseconds before triggering an alarm."
}
