# S3 Module

## Description

Provisions a single AWS S3 bucket. To create multiple buckets, instantiate this module multiple times in your root configuration.

## Inputs

- `s3_bucket_name`: Name of the S3 bucket
- `tags`: Tags to apply to the S3 bucket

## Outputs

- `bucket_id`: ID of the S3 bucket
- `bucket_arn`: ARN of the S3 bucket
- `s3_bucket_name`: Name of the S3 bucket
- `s3_bucket_arn`: ARN of the S3 bucket

## Example Usage

```hcl
module "s3_media" {
  source         = "./modules/s3"
  s3_bucket_name = "vox-api-media"
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

module "s3_logs" {
  source         = "./modules/s3"
  s3_bucket_name = "vox-api-logs"
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "alb-access-logs"
  }
}
```

## Notes

- This module is designed to create a single S3 bucket per instantiation.
- For multiple buckets, instantiate the module multiple times as shown above.
- Enable server-side encryption for sensitive data.
- Tag resources for environment and management.
