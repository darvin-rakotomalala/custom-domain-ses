#########################################################
# MAIN OUTPUTS
#########################################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = module.iam.iam_role_terraform_execution_arn
}

output "api_invoke_url" {
  description = "POST https://.../<stage>/api/contact"
  value       = module.api_gateway.invoke_url
}

output "api_rest_api_id" {
  description = "The ID of the API Gateway REST API."
  value       = module.api_gateway.rest_api_id
}

output "api_stage_name" {
  description = "The name of the API Gateway deployment stage."
  value       = module.api_gateway.stage_name
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "The Amazon Resource Name (ARN) identifying the Lambda function."
  value       = module.lambda.function_arn
}

output "lambda_alias_arn" {
  description = "The Amazon Resource Name (ARN) of the Lambda function alias."
  value       = module.lambda.alias_arn
}

output "lambda_alias_invoke_arn" {
  description = "The invocation ARN of the Lambda function alias for API Gateway."
  value       = module.lambda.alias_invoke_arn
}

output "ses_identity_arn" {
  description = "The ARN of the Amazon SES identity (email or domain)."
  value       = module.ses.identity_arn
}

output "ses_dkim_tokens" {
  description = "A list of DKIM tokens generated for SES domain identity verification."
  value       = module.ses.dkim_tokens
}

output "ses_mail_from_domain" {
  description = "The custom MAIL FROM domain used for sending emails via SES."
  value       = module.ses.mail_from_domain
}

output "ses_from_address" {
  description = "The default 'From' email address configured for SES."
  value       = module.ses.from_address
}

output "ses_verified_for_sending" {
  description = "Indicates whether the SES identity is successfully verified for sending emails."
  value       = module.ses.verified_for_sending
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key."
  value       = module.kms.key_arn
}

output "kms_alias" {
  description = "The display alias name associated with the KMS key."
  value       = module.kms.alias_name
}

output "log_group_names" {
  description = "A map containing the CloudWatch log group names for Lambda and API Gateway."
  value = {
    lambda = module.monitoring.lambda_log_group_name
    api    = module.monitoring.api_log_group_name
  }
}

output "alert_topic_arns" {
  description = "A map containing the Amazon SNS topic ARNs for critical and warning alerts."
  value = {
    critical = module.monitoring.critical_topic_arn
    warning  = module.monitoring.warning_topic_arn
  }
}

output "dashboard_name" {
  description = "The name of the CloudWatch monitoring dashboard."
  value       = module.monitoring.dashboard_name
}

output "lambda_artifacts_bucket_name" {
  description = "Name of the S3 bucket that stores Lambda deployment packages"
  value       = module.s3.lambda_artifacts_bucket_name
}
