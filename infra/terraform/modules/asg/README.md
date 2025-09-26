# ASG Module

## Description

Provisions a single AWS Security Group for ECS tasks. To create multiple security groups, instantiate this module multiple times in your root configuration.

## Inputs

- `sg_name`: Name of the security group
- `vpc_id`: VPC ID
- `allowed_cidr_blocks`: Allowed CIDR blocks for ingress

## Outputs

- `security_group_id`: ID of the security group

## Example Usage

```hcl
module "asg_1" {
  source              = "./modules/asg"
  sg_name             = "vox-api-ecs-sg-1"
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = ["10.0.0.0/16"]
}

module "asg_2" {
  source              = "./modules/asg"
  sg_name             = "vox-api-ecs-sg-2"
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = ["10.0.1.0/24"]
}
```

## Notes

- This module is designed to create a single security group per instantiation.
- For multiple security groups, instantiate the module multiple times as shown above.
