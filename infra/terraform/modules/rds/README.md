# RDS Module

## Description

Provisions a single AWS RDS PostgreSQL instance using the official Terraform AWS module. To create multiple RDS instances, instantiate this module multiple times in your root configuration.

## Inputs

- `rds_identifier`: RDS instance identifier
- `rds_instance_class`: RDS instance class
- `db_username`: Database username
- `db_password`: Database password
- `db_name`: Database name
- `vpc_security_group_ids`: Security group IDs
- `subnet_ids`: Subnet IDs for RDS

## Outputs

- `rds_instance_id`: RDS instance ID
- `rds_endpoint`: RDS endpoint
- `rds_port`: RDS port

## Example Usage

```hcl
module "rds_1" {
  source                 = "./modules/rds"
  rds_identifier         = "example-rds-1"
  rds_instance_class     = "db.t3.micro"
  db_username            = "postgres"
  db_password            = "password"
  db_name                = "exampledb1"
  vpc_security_group_ids = ["sg-12345678"]
  subnet_ids             = ["subnet-123", "subnet-456"]
}

module "rds_2" {
  source                 = "./modules/rds"
  rds_identifier         = "example-rds-2"
  rds_instance_class     = "db.t3.micro"
  db_username            = "postgres"
  db_password            = "password"
  db_name                = "exampledb2"
  vpc_security_group_ids = ["sg-12345678"]
  subnet_ids             = ["subnet-789", "subnet-012"]
}
```

## Notes

- This module wraps an upstream module and may create supporting resources, but is intended for a single RDS instance per instantiation.
- For multiple instances, instantiate the module multiple times as shown above.
- Storage encryption and multi-AZ are enabled by default.
- Backups are retained for 7 days.
- RDS is placed in private subnets for security.
