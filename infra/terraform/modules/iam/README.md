# IAM Module

## Description

Provisions a single AWS IAM role for ECS task execution. To create multiple roles, instantiate this module multiple times in your root configuration.

## Inputs

- `role_name`: Name of the IAM role
- `inline_policy_json`: Inline policy JSON for the role
- `tags`: Tags to apply to the IAM role

## Outputs

- `role_id`: ID of the IAM role
- `role_arn`: ARN of the IAM role

## Example Usage

```hcl
module "ecs_task_role_1" {
  source            = "./modules/iam"
  role_name         = "ecs-task-execution-role-1"
  inline_policy_json = data.aws_iam_policy_document.task_policy_1.json
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

module "ecs_task_role_2" {
  source            = "./modules/iam"
  role_name         = "ecs-task-execution-role-2"
  inline_policy_json = data.aws_iam_policy_document.task_policy_2.json
  tags = {
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
```

## Notes

- This module is designed to create a single IAM role per instantiation.
- For multiple roles, instantiate the module multiple times as shown above.
