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

This project uses an S3 backend for Terraform state and DynamoDB for state locking. **You must create these resources before running `terraform init`:**

- S3 bucket: `vox-api-terraform-state` (in `us-east-1`)
- DynamoDB table: `vox-api-terraform-lock` (with primary key `LockID`)

Example AWS CLI commands:

```sh
aws s3api create-bucket --bucket vox-api-terraform-state --region us-east-1
aws dynamodb create-table \
  --table-name vox-api-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

If you see `NoSuchBucket` or backend errors on `terraform init`, ensure the bucket and table exist and retry after a minute.

## Environment Variables

- `AWS_REGION`: AWS region to deploy resources
- `VPC_CIDR`: CIDR block for the VPC
- `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`: RDS database credentials
- `S3_BUCKET_NAME`: S3 bucket for media/static files
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
3. **Create the S3 bucket and DynamoDB table for remote state (see above).**
4. Run `terraform init` to initialize modules.
5. Run `terraform plan` to review changes.
6. Run `terraform apply` to provision infrastructure.

## Maintenance

- Rotate secrets and credentials regularly.
- Monitor CloudWatch logs and VPC flow logs.
- Update module versions for security patches.
- Review IAM policies and security group rules periodically.
