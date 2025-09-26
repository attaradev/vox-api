# ASM Module

## Description

Provisions a single AWS Secrets Manager secret and policy. To create multiple secrets, instantiate this module multiple times in your root configuration.

## Inputs

- `secret_name`: Name of the secret
- `secret_string`: Secret value (JSON string)
- `secret_access_policy_json`: Resource policy for secret access

## Outputs

- `secret_id`: ID of the secret
- `secret_arn`: ARN of the secret

## Example Usage

```hcl
module "asm_db" {
  source                  = "./modules/asm"
  secret_name             = "vox-api-db-credentials"
  secret_string           = jsonencode({ username = "user" password = "pass" })
  secret_access_policy_json = data.aws_iam_policy_document.db_secret_policy.json
}

module "asm_app" {
  source                  = "./modules/asm"
  secret_name             = "vox-api-app-secret"
  secret_string           = jsonencode({ key = "value" })
  secret_access_policy_json = data.aws_iam_policy_document.app_secret_policy.json
}
```

## Notes

- This module is designed to create a single secret per instantiation.
- For multiple secrets, instantiate the module multiple times as shown above.
