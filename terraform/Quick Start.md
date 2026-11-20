## Build and Deploy a Serverless Contact-Form Email Service on AWS (Terraform)

> **AWS SES custom domain · Lambda · API Gateway · Spring Boot 4 · Terraform**

Spring Boot 4 (Java 21) on AWS Lambda + API Gateway, sending mail through Amazon SES with a custom domain.
Everything is provisioned with Terraform and deployed by GitHub Actions through OIDC.

### Deploy

```bash
$ cd custom-domain-ses/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

### Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```
