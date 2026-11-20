###########################################
## API GATEWAY VARIABLES
###########################################

variable "api_name" {
  description = "The name of the API Gateway REST API."
  type        = string
}

variable "stage_name" {
  description = "The name of the API Gateway stage (e.g., prod, dev, staging)."
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the underlying Lambda function invoked by the API."
  type        = string
}

variable "lambda_alias_name" {
  description = "The name of the Lambda function alias (e.g., live, stable)."
  type        = string
}

variable "lambda_alias_invoke_arn" {
  description = "The invocation ARN of the Lambda function alias."
  type        = string
}

variable "access_log_group_arn" {
  description = "The ARN of the CloudWatch log group used for API Gateway access logging."
  type        = string
}

variable "cors_allowed_origin" {
  description = "Single origin echoed on gateway-generated errors (429/403/5xx)."
  type        = string
}

variable "stage_throttling_rate_limit" {
  description = "Steady-state requests/second for the whole stage."
  type        = number
  default     = 20
}

variable "stage_throttling_burst_limit" {
  description = "Burst requests limit for the whole stage."
  type        = number
  default     = 40
}

variable "enable_method_throttling" {
  description = "Whether to enable fine-grained method-level throttling settings."
  type        = bool
  default     = true
}

variable "method_throttling_rate_limit" {
  description = "Steady-state requests/second limit for specific API methods."
  type        = number
  default     = 5
}

variable "method_throttling_burst_limit" {
  description = "Burst requests limit for specific API methods."
  type        = number
  default     = 10
}

variable "manage_account_settings" {
  description = "Create the account-level CloudWatch role for API Gateway. Set false if it is already configured in this region."
  type        = bool
  default     = true
}

variable "cloudwatch_role_name" {
  description = "The name of the IAM role used by API Gateway to push logs to CloudWatch."
  type        = string
  default     = "api-gateway-cloudwatch-logs"
}
