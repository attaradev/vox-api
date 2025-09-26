# CloudWatch Module

## Description

Provisions a single AWS CloudWatch log group. To create multiple log groups, instantiate this module multiple times in your root configuration.

## Inputs

- `log_group_name`: Name of the log group
- `kms_key_id`: KMS key for encryption

## Outputs

- `log_group_id`: ID of the log group
- `log_group_arn`: ARN of the log group

## Example Usage

```hcl
module "cloudwatch_logs_1" {
  source         = "./modules/cloudwatch"
  log_group_name = "vox-api-ecs-logs-1"
  kms_key_id     = var.kms_key_id
}

module "cloudwatch_logs_2" {
  source         = "./modules/cloudwatch"
  log_group_name = "vox-api-ecs-logs-2"
  kms_key_id     = var.kms_key_id
}
```

## Notes

- This module is designed to create a single log group per instantiation.
- For multiple log groups, instantiate the module multiple times as shown above.
