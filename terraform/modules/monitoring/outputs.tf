###########################################
## MONITORING OUTPUTS
###########################################

output "lambda_log_group_name" {
  value       = aws_cloudwatch_log_group.lambda.name
  description = "The name of the CloudWatch log group for the Lambda function."
}

output "lambda_log_group_arn" {
  value       = aws_cloudwatch_log_group.lambda.arn
  description = "The Amazon Resource Name (ARN) of the Lambda CloudWatch log group."
}

output "api_log_group_name" {
  value       = aws_cloudwatch_log_group.api.name
  description = "The name of the CloudWatch log group for API Gateway."
}

output "api_log_group_arn" {
  value       = aws_cloudwatch_log_group.api.arn
  description = "The Amazon Resource Name (ARN) of the API Gateway CloudWatch log group."
}

output "critical_topic_arn" {
  value       = aws_sns_topic.critical.arn
  description = "The Amazon Resource Name (ARN) of the critical SNS topic."
}

output "warning_topic_arn" {
  value       = aws_sns_topic.warning.arn
  description = "The Amazon Resource Name (ARN) of the warning SNS topic."
}

output "dashboard_name" {
  value       = aws_cloudwatch_dashboard.this.dashboard_name
  description = "The name of the CloudWatch dashboard."
}
