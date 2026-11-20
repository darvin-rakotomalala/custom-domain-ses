###########################################
## IAM
###########################################

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = var.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Logs: scoped to the single log group (tighter than AWSLambdaBasicExecutionRole, which allows
# logs:CreateLogGroup on "*"; Terraform already creates the KMS-encrypted log group).
data "aws_iam_policy_document" "logs" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${var.lambda_log_group_arn}:*"]
  }
}

# Extra SES identities the Lambda may send from (e.g. a verified Gmail address used as the From).
variable "ses_additional_identity_arns" {
  type        = list(string)
  description = "Additional SES identity ARNs the Lambda role may send from."
  default     = ["arn:aws:ses:us-east-1:583524027596:identity/darvintojo@gmail.com"]
}

# SES: send only via the verified identity / configuration set, and only from the expected address.
data "aws_iam_policy_document" "ses" {
  statement {
    effect  = "Allow"
    actions = ["ses:SendEmail"]
    resources = concat(
      [var.ses_identity_arn, var.ses_configuration_set_arn],
      var.ses_additional_identity_arns
    )

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.ses_from_address]
    }
  }
}

data "aws_iam_policy_document" "kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "logs" {
  name   = "${var.naming_prefix}-cloudwatch-logs"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role_policy" "ses" {
  name   = "${var.naming_prefix}-ses-send"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.ses.json
}

resource "aws_iam_role_policy" "kms" {
  name   = "${var.naming_prefix}-kms-project-key"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.kms.json
}
