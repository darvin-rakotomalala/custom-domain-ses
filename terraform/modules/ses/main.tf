###########################################
## SES
###########################################

locals {
  mail_from_domain = "${var.mail_from_subdomain}.${var.domain_name}"

  dmarc_value = join("; ", compact([
    "v=DMARC1",
    "p=${var.dmarc_policy}",
    var.dmarc_report_email == "" ? "" : "rua=mailto:${var.dmarc_report_email}",
    "adkim=r",
    "aspf=r",
  ]))
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# Configuration set: enforces TLS, publishes reputation metrics, auto-suppresses bounces/complaints.
resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = "${var.project}-${var.environment}"

  delivery_options {
    tls_policy = "REQUIRE"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }

  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }
}

# Domain identity with Easy DKIM (RSA 2048).
resource "aws_sesv2_email_identity" "domain" {
  email_identity         = var.domain_name
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

# Dedicated MAIL FROM subdomain -> SPF alignment for DMARC.
resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  email_identity         = aws_sesv2_email_identity.domain.email_identity
  mail_from_domain       = local.mail_from_domain
  behavior_on_mx_failure = var.behavior_on_mx_failure
}

# ---- DNS (Route 53) -------------------------------------------------------------------------

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = var.dns_ttl
  records = ["${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "mail_from_mx" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.mail_from_domain
  type    = "MX"
  ttl     = var.dns_ttl
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.mail_from_domain
  type    = "TXT"
  ttl     = var.dns_ttl
  records = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "dmarc" {
  count   = var.create_dmarc_record ? 1 : 0
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = var.dns_ttl
  records = [local.dmarc_value]
}

# Optional: while the SES account is in the sandbox, only verified recipients receive mail.
resource "aws_sesv2_email_identity" "recipient" {
  count          = var.verify_recipient_identity ? 1 : 0
  email_identity = var.recipient_email
}
