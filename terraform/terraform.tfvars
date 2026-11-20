# ─── Adjust for your environment ────────────────────────────────────
primary_region = "us-east-1"
environment    = "dev"
project_name   = "contact-form"
team_name      = "training"
cost_center    = "engineering"
compliance     = "internal"
owner          = "darvin"
github_org     = "darvin-rakotomalala"
github_repo    = "custom-domain-ses"

domain_name               = "cloudwithdarvin.com"
from_subdomain            = "contact"
from_local_part           = "no-reply"
mail_from_subdomain       = "mail"
recipient_email           = "darvintojo@gmail.com"
behavior_on_mx_failure    = "REJECT_MESSAGE"
verify_recipient_identity = true

# Start in monitoring mode; tighten to quarantine/reject once DMARC reports look clean.
dmarc_policy            = "none"
dmarc_report_email      = ""
create_dmarc_record     = true
from_address            = "no-reply@cloudwithdarvin.com"
dns_ttl                 = 300
deletion_window_in_days = 7

/*
# Explicit browser origins only (no wildcard). Add your local dev server if needed.
cors_allowed_origins = [
  "https://cloudwithdarvin.com",
  "https://www.cloudwithdarvin.com",
]
*/

# Names must be unique per environment when dev and prod share an account/region.
lambda_function_name           = "sesCustomDomainBackend"
lambda_description             = "AWS Serverless Spring Boot 4 API"
lambda_log_group_name          = "SpringBoot_SESCustomDomainBackend_Logs"
lambda_handler                 = "com.ce.StreamLambdaHandler::handleRequest"
lambda_role_name               = "sesCustomDomainBackend-role"
lambda_memory_size             = 1024
lambda_timeout                 = 29
lambda_reserved_concurrency    = -1
lambda_provisioned_concurrency = 0
runtime                        = "java21"
architecture                   = "x86_64"
alias_name                     = "lambda-dev"

api_name                      = "sesCustomDomainRestApi"
stage_name                    = "dev"
api_log_group_name            = "SpringBoot_SESCustomDomainBackendApi_Logs"
cors_allowed_origin           = "*"
stage_throttling_rate_limit   = 20
stage_throttling_burst_limit  = 40
enable_method_throttling      = true
method_throttling_rate_limit  = 5
method_throttling_burst_limit = 10
manage_account_settings       = true

# Dynamic-scaling guard rails
api_stage_rate_limit       = 50
api_stage_burst_limit      = 100
api_method_rate_limit      = 10
api_method_burst_limit     = 20
cloudwatch_role_name       = "api-gateway-cloudwatch-logs"
manage_api_gateway_account = true

alert_emails       = ["darvintojo@gmail.com"]
log_retention_days = 30
enable_waf         = false
rate_limit_per_ip  = 100

critical_https_endpoint              = ""
lambda_concurrency_alarm_threshold   = 800
api_5xx_threshold_per_minute         = 3
api_4xx_threshold_per_5min           = 25
api_latency_threshold_ms             = 5000
api_integration_latency_threshold_ms = 4000
