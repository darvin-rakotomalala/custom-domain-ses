###########################################
## IAM OUTPUTS
###########################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = aws_iam_role.terraform_execution.arn
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda.arn
  description = "The Amazon Resource Name (ARN) specifying the IAM role."
}

output "lambda_role_name" {
  value       = aws_iam_role.lambda.name
  description = "The name of the IAM role."
}
