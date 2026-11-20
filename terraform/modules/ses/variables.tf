###########################################
## SES VARIABLES
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

variable "domain_name" {
  type        = string
  description = "Domain registered/hosted in Route 53, e.g. cloudwithdarvin.com."
}

variable "from_address" {
  type        = string
  description = "Visible From address (on the verified domain), e.g. no-reply@contact.cloudwithdarvin.com."
}

variable "mail_from_subdomain" {
  type        = string
  default     = "mail"
  description = "Dedicated MAIL FROM subdomain label (used for nothing else)."
}

variable "behavior_on_mx_failure" {
  type        = string
  default     = "REJECT_MESSAGE"
  description = "USE_DEFAULT_VALUE or REJECT_MESSAGE. REJECT_MESSAGE keeps SPF alignment for DMARC (recommended in production)."

  validation {
    condition     = contains(["USE_DEFAULT_VALUE", "REJECT_MESSAGE"], var.behavior_on_mx_failure)
    error_message = "Must be USE_DEFAULT_VALUE or REJECT_MESSAGE."
  }
}

variable "dmarc_policy" {
  type        = string
  default     = "none"
  description = "none | quarantine | reject. Start with none, tighten once reports look clean."

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "Must be none, quarantine or reject."
  }
}

variable "dmarc_report_email" {
  type        = string
  default     = ""
  description = "Mailbox for DMARC aggregate reports (rua). Empty = omit."
}

variable "create_dmarc_record" {
  type        = bool
  default     = true
  description = "Set to false if a _dmarc record already exists on the domain."
}

variable "dns_ttl" {
  type        = number
  default     = 300
  description = "The Time To Live (TTL) value in seconds for DNS records."
}

variable "verify_recipient_identity" {
  type        = bool
  default     = false
  description = "Create an email identity for the recipient (needed while the SES account is in the sandbox)."
}

variable "recipient_email" {
  type        = string
  description = "The email address of the recipient."
}
