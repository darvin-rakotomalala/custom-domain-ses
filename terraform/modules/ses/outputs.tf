###########################################
## SES OUTPUTS
###########################################

output "identity_arn" {
  value       = aws_sesv2_email_identity.domain.arn
  description = "The Amazon Resource Name (ARN) of the SES email identity."
}

output "identity_name" {
  value       = aws_sesv2_email_identity.domain.email_identity
  description = "The name of the email identity (domain or email address)."
}

output "dkim_tokens" {
  value       = aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens
  description = "A list of DKIM tokens used to generate CNAME records for domain authentication."
}

output "mail_from_domain" {
  value       = local.mail_from_domain
  description = "The custom MAIL FROM domain used for sending emails."
}

output "from_address" {
  value       = var.from_address
  description = "The default email address used as the sender."
}

output "configuration_set_name" {
  value       = aws_sesv2_configuration_set.this.configuration_set_name
  description = "The name of the SESv2 configuration set."
}

output "configuration_set_arn" {
  value       = aws_sesv2_configuration_set.this.arn
  description = "The Amazon Resource Name (ARN) of the SESv2 configuration set."
}

output "verified_for_sending" {
  value       = aws_sesv2_email_identity.domain.verified_for_sending_status
  description = "May read false right after apply; DNS propagation takes a few minutes."
}
