######################################
# DATA SOURCES
######################################

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# Look up the existing hosted zone (no new zone is created)
data "aws_route53_zone" "existing" {
  name         = var.domain_name
  private_zone = false
}
