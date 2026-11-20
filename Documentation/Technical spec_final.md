# Technical Specification: Serverless Contact-Form Email Service

**AWS SES custom domain · Lambda · API Gateway · Spring Boot 4 · Terraform**

## 1. Overview

### 1.1 Purpose

This document specifies a serverless REST API that receives contact-form submissions from a website and emails them to
the site owner through Amazon Simple Email Service (SES), using a verified custom domain. All infrastructure is
provisioned with Terraform.

### 1.2 Goals

- Deliver contact-form messages reliably from a branded sender address on the custom domain.
- Run fully serverless, with pay-per-use cost and no servers to manage.
- Authenticate outgoing mail with DKIM, SPF and DMARC to maximise deliverability.
- Encrypt logs and mail-related data with a customer-managed KMS key.
- Apply least-privilege IAM and provide observability through metrics, logs and alarms.

### 1.3 Non-goals

- Marketing or bulk email campaigns.
- Inbound email processing (receiving mail via SES).

### 1.4 Why Amazon SES

Amazon SES is a cloud-based email service for transactional, notification and marketing email.

| Capability     | Benefit                                                    |
|----------------|------------------------------------------------------------|
| Scalability    | Handles large sending volumes without capacity planning.   |
| Deliverability | Benefits from AWS sender reputation and dedicated tooling. |
| Cost           | Pay-as-you-go pricing.                                     |
| Security       | Supports DKIM, SPF and DMARC authentication.               |

### 1.5 Learning outcomes

- Infrastructure as Code with Terraform
- Serverless APIs with API Gateway and Lambda
- SES identity verification and email sending
- Data storage in DynamoDB *(optional, see open question Q1)*
- Least-privilege IAM policies
- CORS handling and input validation for web forms

## 2. Architecture

![setting-up-asw-ses.png](../setting-up-asw-ses.png)

### 2.1 Request flow

1. A visitor submits the contact form, which sends a `POST` request to the API Gateway endpoint.
2. API Gateway invokes the Lambda function through the `lambda-dev` alias.
3. The Spring Boot application validates the payload and calls SES to email the message to the site owner.
4. Lambda returns a success or error response to the front end.
5. Logs and metrics are written to CloudWatch, encrypted with the KMS key.

### 2.2 Components

| Component          | Role                                                               |
|--------------------|--------------------------------------------------------------------|
| Route 53           | DNS hosting and automatic publication of SES verification records. |
| Amazon SES         | Domain identity, DKIM signing and email delivery.                  |
| AWS Lambda         | Runs the Spring Boot API (Java 21, SnapStart enabled).             |
| API Gateway (REST) | Public HTTPS entry point, throttling and access logging.           |
| AWS KMS            | Customer-managed key for log and mail-related encryption.          |
| CloudWatch         | Log groups, metric filters, dashboards and alarms.                 |
| Terraform          | Provisioning and lifecycle of all resources above.                 |

## 3. Technology Stack and Prerequisites

| Item                   | Requirement                                                                                        |
|------------------------|----------------------------------------------------------------------------------------------------|
| Language / runtime     | Java 21                                                                                            |
| Framework              | Spring Boot 4                                                                                      |
| Build tool             | Maven                                                                                              |
| Infrastructure as Code | Terraform                                                                                          |
| Cloud                  | AWS account with permissions to manage SES, Lambda, API Gateway, KMS, IAM, CloudWatch and Route 53 |

## 4. Amazon SES Custom Domain

### 4.1 Identity configuration

| Setting                 | Value                                                      |
|-------------------------|------------------------------------------------------------|
| Identity type           | Domain                                                     |
| Domain                  | `cloudwithdarvin.com` (registered and hosted in Route 53)  |
| Sender address          | Address on `contact.cloudwithdarvin.com`                   |
| Custom MAIL FROM domain | `contact.cloudwithdarvin.com` *(see recommendation below)* |
| Behavior on MX failure  | Use default MAIL FROM domain *(see recommendation below)*  |
| DKIM                    | Easy DKIM, RSA 2048-bit, signing enabled                   |
| DNS publishing          | Publish DNS records to Route 53 automatically              |
| Recipient               | `darvintojo@gmail.com`                                     |

### 4.2 DNS records

The following records are created in the Route 53 hosted zone (automatically or via Terraform):

- Three DKIM `CNAME` records generated by Easy DKIM.
- `MX` record for the MAIL FROM domain, pointing to the regional SES feedback endpoint.
- `TXT` (SPF) record for the MAIL FROM domain, for example `v=spf1 include:amazonses.com ~all`.
- `TXT` DMARC record at `_dmarc.cloudwithdarvin.com`, starting with `p=none` and moving to `quarantine` or `reject` once
  reports look clean.

### 4.3 Procedure

1. Create the SES domain identity for `cloudwithdarvin.com`.
2. Enable Easy DKIM with RSA 2048-bit signing.
3. Enable publishing of DNS records to Route 53 (or create them with Terraform).
4. Configure the custom MAIL FROM domain.
5. Wait until the identity and DKIM status show **Verified**.
6. Request SES production access if the account is still in the sandbox.
7. Export Terraform outputs (identity ARN, DKIM tokens, MAIL FROM domain).

> **Why DKIM matters:** missing or misconfigured DKIM significantly harms deliverability and increases the likelihood of
> messages landing in spam.

### 4.4 Recommendations

- **Use a dedicated MAIL FROM subdomain** (for example `mail.cloudwithdarvin.com`) that is not used for anything else.
  Keep `contact.cloudwithdarvin.com` as the visible From domain.
- **Set behavior on MX failure carefully.** The default fallback sends with an `amazonses.com` envelope sender, which
  breaks SPF alignment for DMARC. For production, consider *Reject message* once the MX record is confirmed.
- **SES sandbox:** while in the sandbox, SES only delivers to verified recipients. Verify `darvintojo@gmail.com` or
  request production access.

## 5. AWS Lambda Function

### 5.1 Configuration

| Setting            | Value                                                                                                 |
|--------------------|-------------------------------------------------------------------------------------------------------|
| Function name      | `sesCustomDomainBackend`                                                                              |
| Description        | AWS Serverless Spring Boot 4 API                                                                      |
| Runtime            | Java 21                                                                                               |
| Architecture       | `x86_64`                                                                                              |
| Handler            | `com.ce.StreamLambdaHandler::handleRequest`                                                           |
| Memory             | 1024 MB (starting point; tune using measurements)                                                     |
| Timeout            | 29 seconds or less, to match the API Gateway integration limit (see note below)                       |
| Deployment package | JAR uploaded to the artifacts S3 bucket                                                               |
| Execution role     | `AWSLambdaBasicExecutionRole` plus custom SES and KMS policies (see 5.3)                              |
| Log group          | `SpringBoot_SESCustomDomainBackend_Logs`, KMS-encrypted, set via the function's logging configuration |
| Trigger            | API Gateway (alias `lambda-dev`)                                                                      |
| Terraform outputs  | Function name, ARN, alias ARN, invoke ARN                                                             |

> **Note:** the draft used a 30-second Lambda timeout. Because the effective API Gateway limit is 29 seconds, a Lambda
> timeout above that only wastes billed time. Setting it to 29 seconds or lower is cleaner.

### 5.2 Application model

The request payload maps to a Java entity with four fields:

| Field           | Description             | Validation (recommended)     |
|-----------------|-------------------------|------------------------------|
| `senderName`    | Name of the visitor     | Required, max length 100     |
| `senderEmail`   | Visitor's email address | Required, valid email format |
| `senderSubject` | Message subject         | Required, max length 150     |
| `senderMessage` | Message body            | Required, max length 5000    |

Use Bean Validation (`jakarta.validation`) and return `400` with a clear error body on invalid input. Place the
visitor's address in the `Reply-To` header, never in `From`, so that SES sends only from the verified domain.

### 5.3 IAM execution role

The execution role grants the function only what it needs:

| Permission                                          | Scope                                 |
|-----------------------------------------------------|---------------------------------------|
| `AWSLambdaBasicExecutionRole`                       | CloudWatch Logs write access          |
| `ses:SendEmail`, `ses:SendRawEmail`                 | Restricted to the SES identity ARN    |
| `kms:Decrypt`, `kms:GenerateDataKey`, `kms:Encrypt` | Restricted to the project KMS key ARN |

### 5.4 Cold-start strategy

- Enable **SnapStart** with `apply_on = PublishedVersions` to reduce Java cold starts from seconds to hundreds of
  milliseconds.
- Publish a new version on every deployment (`publish = true`) and point the alias `lambda-dev` to it.
- API Gateway **must invoke the alias**, not `$LATEST`; otherwise SnapStart does not apply.
- Keep the architecture on `x86_64`. Check current ARM64 (Graviton) SnapStart support in the AWS documentation before
  switching.

## 6. API Gateway

### 6.1 Configuration

| Setting           | Value                                                                            |
|-------------------|----------------------------------------------------------------------------------|
| API type / name   | REST API, `sesCustomDomainRestApi`                                               |
| Endpoint type     | `REGIONAL`                                                                       |
| Resource / method | `/{proxy+}` with method `ANY`                                                    |
| Integration       | Lambda proxy integration targeting the `lambda-dev` alias                        |
| Stage             | `dev`, with a new deployment on every API change                                 |
| Access logs       | Log group `SpringBoot_SESCustomDomainBackendApi_Logs`, KMS-encrypted             |
| Metrics           | Detailed metrics enabled on the stage                                            |
| Throttling        | Stage-level and method-level rate and burst limits to protect Lambda concurrency |
| Caching           | Not applicable to the `POST` contact endpoint (see note below)                   |
| Terraform outputs | Invoke URL, REST API ID, stage name                                              |

## 7. AWS KMS

- Create a customer-managed KMS key with automatic key rotation enabled.
- Use it to encrypt the CloudWatch log groups (and any other data at rest in the project).
- Key policy: allow the CloudWatch Logs service principal (`logs.<region>.amazonaws.com`) to use the key, scoped by
  encryption context to the project log-group ARNs.
- Grant the Lambda execution role the minimum `Encrypt`, `Decrypt` and `GenerateDataKey` permissions.
- Export the key ARN and alias as Terraform outputs.

## 8. Observability: CloudWatch

### 8.1 Lambda log group

**Name:** `SpringBoot_SESCustomDomainBackend_Logs` (KMS-encrypted, with a defined retention period)

| Signal              | Filter pattern                                            | Purpose                                |
|---------------------|-----------------------------------------------------------|----------------------------------------|
| Function timeout    | `"Task timed out after"`                                  | Detects imminent or actual timeouts    |
| Out-of-memory       | `{ $.status = "OOM" \|\| $.message = "*Out of memory*" }` | Detects memory exhaustion              |
| Unhandled errors    | `?"ERROR" ?"Error" ?"Exception" ?"Unhandled" ?"panic"`    | Detects exceptions and runtime crashes |
| Cold-start tracking | `[type="REPORT", ..., init_duration="Init Duration:"]`    | Measures initialization cost           |
| ERROR metric filter | Pattern on `ERROR`                                        | Emits a custom error-count metric      |
| WARN metric filter  | Pattern on `WARN`                                         | Emits a custom warning-count metric    |

**Alarms** notify the team when:

- The function reaches account or reserved concurrency limits.
- Errors, unhandled exceptions or runtime crashes occur.
- Latency is high, which signals a bottleneck or imminent timeouts.
- Throttling occurs.

### 8.2 API Gateway log group

**Name:** `SpringBoot_SESCustomDomainBackendApi_Logs` (KMS-encrypted, with a defined retention period)

| Alarm                                                   | Severity | Action                                            |
|---------------------------------------------------------|----------|---------------------------------------------------|
| High 5xx error rate (errors per minute above threshold) | Critical | Page via PagerDuty or OpsGenie                    |
| Spike in 4xx error rate                                 | Warning  | Notify Slack or email                             |
| High overall latency                                    | Warning  | Indicates an API bottleneck                       |
| High integration latency                                | Warning  | Indicates a backend dependency issue (Lambda, DB) |
| API throttling                                          | Warning  | Quota or concurrency limits reached               |

Additional log insights: extract 4xx and 5xx errors by path or endpoint, and report backend delays above a threshold.

> **Convention note:** CloudWatch's default naming is `/aws/lambda/<function>` and `/aws/apigateway/<api>`. The custom
> names above are valid, but whichever scheme is chosen should be applied consistently and referenced through Terraform
> variables.

## 9. Terraform Implementation

### 9.1 Suggested module layout

| Module        | Resources                                                  |
|---------------|------------------------------------------------------------|
| `ses`         | Domain identity, DKIM, MAIL FROM, Route 53 records         |
| `kms`         | Key, alias, key policy                                     |
| `iam`         | Lambda execution role and policies                         |
| `lambda`      | Function, SnapStart, version, alias                        |
| `api_gateway` | REST API, `/{proxy+}` resource, stage, throttling, logging |
| `monitoring`  | Log groups, metric filters, alarms, SNS topics             |

### 9.2 Practices

- Use a remote backend (S3 with state locking) and separate workspaces or variable files per environment.
- Parameterize names, region and domain; avoid hard-coded values.
- Tag all resources consistently (`Project`, `Environment`, `Owner`).
- Every module exposes outputs, and the root module aggregates the key ones: SES identity ARN, KMS key ARN, Lambda alias
  ARN, API invoke URL and log group names.

## 10. Security Summary

- Least-privilege IAM, with SES send access scoped to the verified identity.
- DKIM, SPF and DMARC configured on the sending domain.
- Customer-managed KMS key for log encryption, with rotation.
- Strict CORS, input validation and throttling on the public endpoint.
- No credentials in code; use the Lambda execution role only.

## 11. Testing and Acceptance Criteria

| # | Test                                            | Expected result                              |
|---|-------------------------------------------------|----------------------------------------------|
| 1 | `terraform plan` and `apply` on a clean account | Succeeds and outputs all resources           |
| 2 | SES identity and DKIM status                    | Both show **Verified**                       |
| 3 | Valid `POST` to the invoke URL                  | `200` response and the email is received     |
| 4 | Invalid payload (missing or malformed fields)   | `400` with a descriptive error               |
| 5 | Cross-origin request from the site              | CORS headers present; other origins rejected |
| 6 | Email headers inspected                         | DKIM, SPF and DMARC all **pass**             |
| 7 | Cold start measured with SnapStart              | Init time in the hundreds of milliseconds    |
| 8 | Force an error and a timeout                    | Matching metric filter and alarm fire        |
| 9 | Burst test beyond throttle limits               | Excess requests receive `429`                |
