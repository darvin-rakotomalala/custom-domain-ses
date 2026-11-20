###########################################
## API GATEWAY OUTPUTS
###########################################

output "rest_api_id" {
  description = "The ID of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_name" {
  description = "The name of the API Gateway REST API."
  value       = aws_api_gateway_rest_api.this.name
}

output "stage_name" {
  description = "The name of the API Gateway deployment stage."
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_arn" {
  description = "The Amazon Resource Name (ARN) of the API Gateway stage."
  value       = aws_api_gateway_stage.this.arn
}

output "invoke_url" {
  description = "The URL to invoke the API Gateway stage."
  value       = aws_api_gateway_stage.this.invoke_url
}
