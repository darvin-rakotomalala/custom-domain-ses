###########################################
## KMS
###########################################

data "aws_partition" "current" {}

locals {
  partition = data.aws_partition.current.partition

  # The encryption context CloudWatch Logs sends with every KMS call is the log-group ARN (without ":*").
  log_group_arns = [
    for name in var.log_group_names :
    "arn:${local.partition}:logs:${var.region}:${var.account_id}:log-group:${name}"
  ]
}

data "aws_iam_policy_document" "key" {
  # Standard statement that lets IAM policies (Lambda role, CI role, ...) grant access to the key.
  statement {
    sid       = "EnableIamPolicies"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${var.account_id}:root"]
    }
  }

  # One customer-managed key for: CloudWatch log groups, SNS topics, the S3
  # CloudWatch Logs may use the key ONLY for this project's log groups (encryption-context scoped).
  statement {
    sid    = "AllowCloudWatchLogsForProjectLogGroups"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = local.log_group_arns
    }
  }

  # Lets CloudWatch alarms publish to the KMS-encrypted SNS topics.
  statement {
    sid       = "AllowSnsAndCloudWatchAlarms"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com", "cloudwatch.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid       = "AllowAlarmsAndSesToPublishToEncryptedSns"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com", "ses.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "${var.project}-${var.environment}: encrypts CloudWatch logs and SNS alert topics"
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_in_days
  policy                  = data.aws_iam_policy_document.key.json

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-kms key"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project}-${var.environment}"
  target_key_id = aws_kms_key.this.key_id
}
