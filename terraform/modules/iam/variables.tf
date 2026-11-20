###########################################
## IAM VARIABLES
###########################################

variable "naming_prefix" {
  type        = string
  description = "Naming prefix"
}

variable "common_tags" {
  type        = map(string)
  description = "A map of common tags to assign to resources."
}

variable "current_account_id" {
  type        = string
  description = "Current account ID"
}

variable "github_org" {
  type        = string
  description = "GitHub organization"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository"
}

variable "current_partition" {
  type        = string
  description = "Current partition account ID"
  # default = data.aws_partition.current.partition
}

variable "lambda_role_name" {
  type        = string
  description = "The name of the IAM role."
}

variable "lambda_log_group_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the CloudWatch log group."
}

variable "ses_identity_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the SES email identity."
}

variable "ses_configuration_set_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the SES configuration set."
}

variable "ses_from_address" {
  type        = string
  description = "The email address used as the sender for SES."
}

variable "kms_key_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the KMS key."
}
