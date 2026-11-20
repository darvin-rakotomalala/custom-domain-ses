###########################################
## LAMBDA VARIABLES
###########################################

variable "function_name" {
  description = "The name of the AWS Lambda function."
  type        = string
}

variable "description" {
  description = "The description of the Lambda function."
  type        = string
  default     = "AWS Serverless Spring Boot 4 API"
}

variable "role_arn" {
  description = "The ARN of the IAM role that grants the Lambda function permissions to access AWS services."
  type        = string
}

variable "runtime" {
  description = "The identifier of the function's runtime environment."
  type        = string
  default     = "java21"
}

variable "handler" {
  description = "The function entrypoint in your code where Lambda begins execution."
  type        = string
  default     = "com.ce.StreamLambdaHandler::handleRequest"
}

variable "architecture" {
  description = "Instruction set architecture for your Lambda function. x86_64 or arm64. Check current SnapStart support for arm64 before switching."
  type        = string
  default     = "x86_64"
}

variable "memory_size" {
  description = "The amount of memory, in MB, allocated to the Lambda function."
  type        = number
  default     = 1024
}

variable "timeout" {
  description = "The amount of time, in seconds, that Lambda allows a function to run before stopping it. API Gateway's integration limit is 29s, so never go above that."
  type        = number
  default     = 29

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 29
    error_message = "Timeout must be between 1 and 29 seconds."
  }
}

variable "log_group_name" {
  description = "The name of the CloudWatch log group used for Lambda function logging."
  type        = string
}

variable "alias_name" {
  description = "The name of the Lambda function alias."
  type        = string
}

variable "reserved_concurrency" {
  description = "The maximum number of concurrent executions allocated to the Lambda function (-1 for unreserved)."
  type        = number
  default     = -1
}

variable "provisioned_concurrency" {
  description = "The amount of provisioned concurrency to allocate for the Lambda function alias."
  type        = number
  default     = 0
}

variable "from_address" {
  type        = string
  description = "Visible From address (on the verified domain), e.g. no-reply@contact.cloudwithdarvin.com."
}

variable "recipient_email" {
  type        = string
  description = "The email address of the recipient."
}

variable "configuration_set_name" {
  description = "The name of the SESv2 configuration set."
  type        = string
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

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "A map of environment key-value pairs to pass to the function or service."
}
