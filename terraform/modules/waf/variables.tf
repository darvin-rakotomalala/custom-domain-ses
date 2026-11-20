###########################################
## WAF VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "resource_arn" {
  description = "ARN of the API Gateway stage to protect."
  type        = string
}

variable "rate_limit_per_ip" {
  description = "Max requests per IP per 5 minutes before WAF blocks (minimum 10)."
  type        = number
  default     = 100
}
