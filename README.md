# Build and Deploy a Serverless Contact-Form, AWS SES Custom Domain on AWS (Terraform)

> **AWS SES Custom Domain · Lambda · API Gateway · Spring Boot 4 · Terraform**

Spring Boot 4 (Java 21) on AWS Lambda + API Gateway, sending mail through Amazon SES with a custom domain.
Everything is provisioned with Terraform and deployed by GitHub Actions through OIDC.

---

## Overview

### Purpose

This document specifies a serverless REST API that receives contact-form submissions from a website and emails them to
the site owner through Amazon Simple Email Service (SES), using a verified custom domain. All infrastructure is
provisioned with Terraform.

### Goals

- Deliver contact-form messages reliably from a branded sender address on the custom domain.
- Run fully serverless, with pay-per-use cost and no servers to manage.
- Authenticate outgoing mail with DKIM, SPF and DMARC to maximise deliverability.
- Encrypt logs and mail-related data with a customer-managed KMS key.
- Apply least-privilege IAM and provide observability through metrics, logs and alarms.

### Why Amazon SES

Amazon SES is a cloud-based email service for transactional, notification and marketing email.

| Capability     | Benefit                                                    |
|----------------|------------------------------------------------------------|
| Scalability    | Handles large sending volumes without capacity planning.   |
| Deliverability | Benefits from AWS sender reputation and dedicated tooling. |
| Cost           | Pay-as-you-go pricing.                                     |
| Security       | Supports DKIM, SPF and DMARC authentication.               |

### Learning outcomes

- Infrastructure as Code with Terraform
- Serverless APIs with API Gateway and Lambda
- SES identity verification and email sending
- Data storage in DynamoDB *(optional)*
- Least-privilege IAM policies
- CORS handling and input validation for web forms

---

## Architecture

![setting-up-asw-ses.png](setting-up-asw-ses.png)

### Request flow

1. A visitor submits the contact form, which sends a `POST` request to the API Gateway endpoint.
2. API Gateway invokes the Lambda function through the `lambda-dev` alias.
3. The Spring Boot application validates the payload and calls SES to email the message to the site owner.
4. Lambda returns a success or error response to the front end.
5. Logs and metrics are written to CloudWatch, encrypted with the KMS key.

### Components

| Component          | Role                                                               |
|--------------------|--------------------------------------------------------------------|
| Route 53           | DNS hosting and automatic publication of SES verification records. |
| Amazon SES         | Domain identity, DKIM signing and email delivery.                  |
| AWS Lambda         | Runs the Spring Boot API (Java 21, SnapStart enabled).             |
| API Gateway (REST) | Public HTTPS entry point, throttling and access logging.           |
| AWS KMS            | Customer-managed key for log and mail-related encryption.          |
| CloudWatch         | Log groups, metric filters, dashboards and alarms.                 |
| Terraform          | Provisioning and lifecycle of all resources above.                 |

### Technology Stack and Prerequisites

| Item                   | Requirement                                                                                        |
|------------------------|----------------------------------------------------------------------------------------------------|
| Language / runtime     | Java 21                                                                                            |
| Framework              | Spring Boot 4                                                                                      |
| Build tool             | Maven                                                                                              |
| Infrastructure as Code | Terraform                                                                                          |
| Cloud                  | AWS account with permissions to manage SES, Lambda, API Gateway, KMS, IAM, CloudWatch and Route 53 |

---

## Implementation with Terraform

### Step 1 — Provision the infrastructure

Run the following commands from the root Terraform directory:

```bash
cd custom-domain-ses/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

![1-Outputs.png](Screenshot%20verification/1-Outputs.png)

**Migrating to a remote backend**

1. Add or activate the backend configuration in `terraform/backend.tf`.
2. Re-initialize to migrate the state: `terraform init -migrate-state`.

### Step 2 — Deploy

1. **Bootstrap (once, local state)**
   `cd terraform/bootstrap && terraform init && terraform apply -var github_repository=<owner>/<repo>`
   Copy the outputs into `envs/*.backend.hcl` (state bucket), `envs/*.tfvars` (`artifacts_bucket_name`) and
   GitHub repository variables `AWS_ROLE_ARN`, `STATE_BUCKET`, `ARTIFACTS_BUCKET`.
2. **First deploy by hand** (optional, CI does the same)
   ```
   cd backend && mvn -B package
   aws s3 cp target/ses-contact-backend-1.0.0.jar s3://<artifacts-bucket>/contact-api/manual.jar
   cd ../terraform
   terraform init -backend-config=envs/dev.backend.hcl
   terraform apply -var-file=envs/dev.tfvars -var lambda_s3_key=contact-api/manual.jar
   ```
3. Confirm the SNS e-mail subscriptions and (sandbox) the recipient verification e-mail SES sends.
4. Wait for DKIM = Verified, then request **SES production access** to leave the sandbox.
5. After DMARC reports look clean, raise `dmarc_policy` from `none` to `quarantine`/`reject`.

---

## Verification & Test

### API

`POST {invoke_url}/api/contact`  (invoke URL looks like `https://<id>.execute-api.<region>.amazonaws.com/dev`)

```json
{
  "senderName": "Mamy",
  "senderEmail": "mamy@example.com",
  "senderSubject": "Test SES Custom Domain",
  "senderMessage": "Hello! This is a Test SES Custom Domain"
}
```

![6-POST Create Contact.png](Screenshot%20verification/6-POST%20Create%20Contact.png)

| Result                                    | When                                      |
|-------------------------------------------|-------------------------------------------|
| `200 {"status":"SENT","messageId":"..."}` | accepted by SES                           |
| `400` problem+json with an `errors` map   | missing/invalid/too-long fields, bad JSON |
| `429`                                     | API Gateway / WAF throttling              |
| `502` problem+json                        | SES rejected or was unreachable           |

![7-Email received.png](Screenshot%20verification/7-Email%20received.png)

---

## Summary

This project delivers a serverless contact-form backend that sends email from a branded address on a custom domain.
A Spring Boot 4 (Java 21) application runs on AWS Lambda behind API Gateway and sends mail through Amazon SES.
Terraform provisions all of the infrastructure, and GitHub Actions deploys it through OIDC with no long-lived
credentials.

### What was built

| Area          | Result                                                                                                |
|---------------|-------------------------------------------------------------------------------------------------------|
| API           | `POST /api/contact` with input validation, CORS handling and clear `200`/`400`/`429`/`502` responses. |
| Email         | SES domain identity with DKIM signing, SPF and DMARC, so mail comes from the custom domain.           |
| Compute       | Lambda (Java 21, SnapStart) invoked through the `lambda-dev` alias, with pay-per-use pricing.         |
| DNS           | Route 53 publishes the SES verification records automatically.                                        |
| Security      | Customer-managed KMS key for logs, and least-privilege IAM roles.                                     |
| Observability | CloudWatch log groups, metric filters, dashboards and alarms, with SNS notifications.                 |
| Delivery      | Terraform for all resources, a remote state backend, and CI/CD through GitHub Actions with OIDC.      |

### Key takeaways

- **Deliverability depends on DNS.** DKIM must show *Verified*, and SPF and DMARC must be in place, before mail reliably
  reaches inboxes.
- **The SES sandbox is the first hurdle.** Until you are granted production access, SES only sends to verified
  recipients.
- **Infrastructure as Code keeps environments reproducible.** The same Terraform code and per-environment
  `envs/*.tfvars` files serve every environment.
- **Least privilege and encryption are part of the design.** IAM permissions are scoped narrowly, and logs are encrypted
  with the KMS key.

### Go-live checklist

1. Confirm the SNS e-mail subscriptions and the SES recipient verification e-mail.
2. Wait for DKIM = **Verified**.
3. Request **SES production access** to leave the sandbox.
4. Review DMARC reports, then raise `dmarc_policy` from `none` to `quarantine` or `reject`.
5. Send a test request to `{invoke_url}/api/contact` and check for a `200 {"status":"SENT"}` response.

### Possible next steps

- Store submissions in DynamoDB (optional) to keep a history of messages.
- Add AWS WAF rules or API keys for stronger abuse protection.
- Add a CAPTCHA or honeypot field on the front end to reduce spam.
- Promote the same stack to staging and production environments.
