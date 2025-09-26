# VPC Module

## Description

Provisions a single AWS VPC with public and private subnets, NAT gateway, VPC endpoints, and flow logs using the official Terraform AWS module. To create multiple VPCs, instantiate this module multiple times in your root configuration.

## Inputs

- `vpc_name`: Name of the VPC
- `vpc_cidr`: CIDR block for the VPC
- `azs`: List of availability zones
- `private_subnets`: List of private subnet CIDRs
- `public_subnets`: List of public subnet CIDRs
- `vpc_flow_log_group_name`: CloudWatch log group name for VPC flow logs
- `vpc_flow_log_role_arn`: IAM role ARN for VPC flow logs

## Outputs

- `vpc_id`: VPC ID
- `private_subnets`: Private subnet IDs
- `public_subnets`: Public subnet IDs
- `private_route_table_ids`: Private route table IDs

## Example Usage

```hcl
module "vpc_1" {
  source          = "./modules/vpc"
  vpc_name        = "example-vpc-1"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  vpc_flow_log_group_name = "example-flow-logs-1"
  vpc_flow_log_role_arn   = "arn:aws:iam::123456789012:role/flow-logs-role"
}

module "vpc_2" {
  source          = "./modules/vpc"
  vpc_name        = "example-vpc-2"
  vpc_cidr        = "10.1.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]
  vpc_flow_log_group_name = "example-flow-logs-2"
  vpc_flow_log_role_arn   = "arn:aws:iam::123456789012:role/flow-logs-role"
}
```

## Notes

- This module wraps an upstream module and may create supporting resources, but is intended for a single VPC per instantiation.
- For multiple VPCs, instantiate the module multiple times as shown above.
- Flow logs and endpoints are enabled for security and auditing.
- Tag resources for environment and management.
