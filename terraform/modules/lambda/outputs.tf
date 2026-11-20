###########################################
## LAMBDA OUTPUTS
###########################################

output "function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_version" {
  description = "Latest published version of the Lambda function."
  value       = aws_lambda_function.this.version
}

output "alias_name" {
  description = "The name of the Lambda function alias."
  value       = aws_lambda_alias.this.name
}

output "alias_arn" {
  description = "The Amazon Resource Name (ARN) of the Lambda function alias."
  value       = aws_lambda_alias.this.arn
}

output "alias_invoke_arn" {
  description = "Use this (not the function invoke ARN) as the API Gateway integration URI."
  value       = aws_lambda_alias.this.invoke_arn
}
