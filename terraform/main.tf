#########################################################
# KMS
#########################################################

# 1. KMS -- depends only on static names, so it can be created first.
module "kms" {
  source          = "./modules/kms"
  project         = var.project_name
  environment     = var.environment
  region          = var.primary_region
  account_id      = data.aws_caller_identity.current.account_id
  log_group_names = [var.lambda_log_group_name, var.api_log_group_name]
  naming_prefix   = local.naming_prefix
  common_tags     = local.common_tags
}

#########################################################
# SES
#########################################################

# 2. SES identity, DKIM, MAIL FROM, SPF/DMARC records
module "ses" {
  source                    = "./modules/ses"
  project                   = var.project_name
  environment               = var.environment
  region                    = var.primary_region
  domain_name               = var.domain_name
  from_address              = local.from_address
  mail_from_subdomain       = var.mail_from_subdomain
  behavior_on_mx_failure    = var.behavior_on_mx_failure
  dmarc_policy              = var.dmarc_policy
  dmarc_report_email        = var.dmarc_report_email
  create_dmarc_record       = var.create_dmarc_record
  verify_recipient_identity = var.verify_recipient_identity
  recipient_email           = var.recipient_email
}

#########################################################
# MONITORING
#########################################################

# 3. Log groups, metric filters, alarms, SNS, dashboard
#    (alarm dimensions use the static names below, so this module does not depend on Lambda/API resources)
module "monitoring" {
  source                  = "./modules/monitoring"
  project                 = var.project_name
  environment             = var.environment
  region                  = var.primary_region
  kms_key_arn             = module.kms.key_arn
  lambda_function_name    = var.lambda_function_name
  lambda_log_group_name   = var.lambda_log_group_name
  lambda_timeout_seconds  = var.lambda_timeout
  api_name                = var.api_name
  api_stage_name          = local.stage_name
  api_log_group_name      = var.api_log_group_name
  log_retention_days      = var.log_retention_days
  alert_emails            = var.alert_emails
  critical_https_endpoint = var.critical_https_endpoint
}

#########################################################
# IAM
#########################################################

# 4. Least-privilege execution role
module "iam" {
  source                    = "./modules/iam"
  current_account_id        = data.aws_caller_identity.current.account_id
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  github_org                = var.github_org
  github_repo               = var.github_repo
  current_partition         = data.aws_partition.current.partition
  ses_identity_arn          = module.ses.identity_arn
  ses_configuration_set_arn = module.ses.configuration_set_arn
  ses_from_address          = module.ses.from_address
  kms_key_arn               = module.kms.key_arn
  lambda_log_group_arn      = module.monitoring.lambda_log_group_arn
  lambda_role_name          = "${var.project_name}-${var.environment}-lambda-exec"
}

#########################################################
# LAMBDA
#########################################################

# 5. Lambda (Java 21, SnapStart, published version + alias)
module "lambda" {
  source = "./modules/lambda"

  function_name           = var.lambda_function_name
  role_arn                = module.iam.lambda_role_arn
  handler                 = var.lambda_handler
  memory_size             = var.lambda_memory_size
  timeout                 = var.lambda_timeout
  log_group_name          = module.monitoring.lambda_log_group_name
  alias_name              = local.alias_name
  reserved_concurrency    = var.lambda_reserved_concurrency
  provisioned_concurrency = var.lambda_provisioned_concurrency

  environment_variables = {
    SES_FROM_ADDRESS      = module.ses.from_address
    SES_RECIPIENT_ADDRESS = var.recipient_email
    SES_CONFIGURATION_SET = module.ses.configuration_set_name
    CORS_ALLOWED_ORIGINS  = var.cors_allowed_origin
    # CORS_ALLOWED_ORIGINS  = join(",", var.cors_allowed_origin)
    # C1-only JIT: faster start-up / smaller snapshot; plenty for a low-CPU contact form.
    JAVA_TOOL_OPTIONS = "-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
  }

  depends_on             = [module.monitoring] # log group must exist before the function is created
  configuration_set_name = module.ses.configuration_set_name
  # cors_allowed_origins   = []
  from_address    = module.ses.from_address
  recipient_email = var.recipient_email
}

#########################################################
# API GATEWAY
#########################################################

# 6. API Gateway (REST, regional) in front of the Lambda alias
module "api_gateway" {
  source                        = "./modules/api_gateway"
  api_name                      = var.api_name
  stage_name                    = local.stage_name
  lambda_function_name          = module.lambda.function_name
  lambda_alias_name             = module.lambda.alias_name
  lambda_alias_invoke_arn       = module.lambda.alias_invoke_arn
  access_log_group_arn          = module.monitoring.api_log_group_arn
  cors_allowed_origin           = var.cors_allowed_origin
  stage_throttling_rate_limit   = var.api_stage_rate_limit
  stage_throttling_burst_limit  = var.api_stage_burst_limit
  method_throttling_rate_limit  = var.api_method_rate_limit
  method_throttling_burst_limit = var.api_method_burst_limit
  manage_account_settings       = var.manage_api_gateway_account
  cloudwatch_role_name          = "${var.project_name}-${var.environment}-apigw-cloudwatch"
}

#########################################################
# WAF
#########################################################

# 7. Optional WAF
module "waf" {
  source            = "./modules/waf"
  count             = var.enable_waf ? 1 : 0
  resource_arn      = module.api_gateway.stage_arn
  rate_limit_per_ip = var.rate_limit_per_ip
  naming_prefix     = local.naming_prefix
  common_tags       = local.common_tags
}

#########################################################
# S3
#########################################################

module "s3" {
  source        = "./modules/s3"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  kms_key_arn   = module.kms.key_arn
}
