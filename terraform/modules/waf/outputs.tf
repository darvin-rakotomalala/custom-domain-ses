###########################################
## WAF OUTPUTS
###########################################

output "web_acl_arn" {
  value       = aws_wafv2_web_acl.this.arn
  description = "The Amazon Resource Name (ARN) of the WAFv2 Web ACL."
}
