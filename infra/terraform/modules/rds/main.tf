module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier              = var.rds_identifier
  engine                  = "postgres"
  instance_class          = var.rds_instance_class
  allocated_storage       = 20
  username                = var.db_username
  password                = var.db_password
  db_name                 = var.db_name
  vpc_security_group_ids  = var.vpc_security_group_ids
  subnet_ids              = var.subnet_ids
  storage_encrypted       = true
  backup_retention_period = 7
  multi_az                = true
  publicly_accessible     = false
  family                  = var.family
  tags                    = var.tags
}
