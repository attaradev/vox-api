# ALB Module

## Description

Provisions a single AWS Application Load Balancer (ALB) and target group. To create multiple ALBs, instantiate this module multiple times in your root configuration.

## Inputs

- `alb_name`: Name of the ALB
- `security_group_ids`: Security group IDs for the ALB
- `subnet_ids`: Subnet IDs for the ALB
- `target_group_name`: Name of the target group
- `vpc_id`: VPC ID
- `alb_logs_bucket`: S3 bucket for ALB access logs
- `tags`: Tags to apply to the ALB and target group

## Outputs

- `alb_id`: ID of the ALB
- `alb_arn`: ARN of the ALB
- `target_group_arn`: ARN of the target group

## Example Usage

```hcl
module "alb_1" {
  source             = "./modules/alb"
  alb_name           = "vox-api-alb-1"
  security_group_ids = [aws_security_group.alb.id]
  subnet_ids         = module.vpc.public_subnets
  target_group_name  = "vox-api-alb-tg-1"
  vpc_id             = module.vpc.vpc_id
  alb_logs_bucket    = module.s3_logs.s3_bucket_name
  tags               = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

module "alb_2" {
  source             = "./modules/alb"
  alb_name           = "vox-api-alb-2"
  security_group_ids = [aws_security_group.alb.id]
  subnet_ids         = module.vpc.public_subnets
  target_group_name  = "vox-api-alb-tg-2"
  vpc_id             = module.vpc.vpc_id
  alb_logs_bucket    = module.s3_logs.s3_bucket_name
  tags               = {
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
```

## Notes

- This module is designed to create a single ALB per instantiation.
- For multiple ALBs, instantiate the module multiple times as shown above.
