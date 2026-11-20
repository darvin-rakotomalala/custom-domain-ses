###########################################
## KMS VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

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

variable "account_id" {
  type        = string
  description = "The AWS account ID where the resources are provisioned."
}

variable "log_group_names" {
  type        = list(string)
  description = "Names of the log groups this key is allowed to encrypt."
}

variable "deletion_window_in_days" {
  type        = number
  default     = 30
  description = "The waiting period, specified in number of days, before KMS deletes the key after it is destroyed."
}
