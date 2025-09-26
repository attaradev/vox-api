# Vox API Terraform Infrastructure

## Overview

This infrastructure uses Terraform to provision secure, production-ready AWS resources for the Vox API application. All modules follow AWS and Terraform best practices for security, scalability, and maintainability.

## Security Best Practices

- All resources are tagged for environment and management.
- Security groups restrict ingress to trusted CIDRs and only necessary ports.
- S3 buckets block public access and use server-side encryption.
- IAM roles use least privilege and custom inline policies.
- Secrets are stored in AWS Secrets Manager with resource policies.
- RDS and ElastiCache use encryption, backups, and private subnets.
- VPC endpoints and flow logs are enabled for private connectivity and auditing.
- CloudWatch logs are encrypted with KMS.

## Remote State Backend Setup

This project uses an S3 backend for Terraform state with the built-in `.tflock` lock file. **You must create the state bucket before running `terraform init`:**

- S3 bucket: `vox-api-terraform-state` (in `us-east-1`)

Example AWS CLI command:

```sh
aws s3api create-bucket --bucket vox-api-terraform-state --region us-east-1
```

Enable bucket versioning (and optional object-lock) for stronger state protection.

If you see `NoSuchBucket` or backend errors on `terraform init`, ensure the bucket exists and retry after a minute.

## Environment Variables

- `AWS_REGION`: AWS region to deploy resources
- `VPC_CIDR`: CIDR block for the VPC
- `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`: RDS database credentials
- `S3_BUCKET_NAME`: S3 bucket for media/static files
- `ENVIRONMENT`: Deployment environment used for tagging (maps to `var.environment`)
- `TF_VAR_additional_tags`: Additional tags merged into every resource
- See each module README for additional variables

## Module Usage

Each module is documented in its own README with required inputs, outputs, and example usage. See:

- `modules/vpc/README.md`
- `modules/ecs/README.md`
- `modules/rds/README.md`
- `modules/elasticache/README.md`
- `modules/s3/README.md`
- `modules/iam/README.md`
- `modules/alb/README.md`
- `modules/asg/README.md`
- `modules/cloudwatch/README.md`
- `modules/asm/README.md`

## Getting Started

1. Install Terraform and AWS CLI.
2. Configure your AWS credentials.
3. **Create the S3 bucket for remote state (see above).**
4. Run `terraform init` to initialize modules.
5. Run `terraform plan` to review changes.
6. Run `terraform apply` to provision infrastructure.

> **Tip:** When working offline or without AWS credentials, set `TF_VAR_skip_aws_account_checks=true` to bypass provider validation during `terraform init`.
> Provide `TF_VAR_environment` (for example `staging`) to propagate environment-aware naming and tagging.

## Maintenance

- Rotate secrets and credentials regularly.
- Monitor CloudWatch logs and VPC flow logs.
- Update module versions for security patches.
- Review IAM policies and security group rules periodically.
