locals {
  password       = var.existing_master_password != "" ? var.existing_master_password : random_password.master[0].result
  secret_name    = var.secret_name != "" ? var.secret_name : "${var.name_prefix}-db-credentials"
  connection_url = "postgresql://${var.username}:${urlencode(local.password)}@${aws_db_instance.this.address}:${aws_db_instance.this.port}/${var.db_name}"
}

resource "random_password" "master" {
  count = var.existing_master_password == "" ? 1 : 0

  length  = var.password_length
  special = true
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-db"
  description = "Controls access to the RDS instance"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db"
  })
}

resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, sg_id in var.allowed_security_group_ids : tostring(idx) => sg_id }

  description              = "Allow database access from trusted security group"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = each.value
}

resource "aws_db_instance" "this" {
  identifier                            = "${var.name_prefix}-postgres"
  db_name                               = var.db_name
  engine                                = "postgres"
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  allocated_storage                     = var.allocated_storage
  max_allocated_storage                 = var.max_allocated_storage
  username                              = var.username
  password                              = local.password
  db_subnet_group_name                  = aws_db_subnet_group.this.name
  vpc_security_group_ids                = [aws_security_group.this.id]
  skip_final_snapshot                   = false
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.preferred_backup_window
  maintenance_window                    = var.preferred_maintenance_window
  multi_az                              = var.multi_az
  storage_encrypted                     = var.storage_encrypted
  kms_key_id                            = length(var.kms_key_id) > 0 ? var.kms_key_id : null
  deletion_protection                   = var.deletion_protection
  copy_tags_to_snapshot                 = true
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention
  apply_immediately                     = var.apply_immediately
  publicly_accessible                   = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
  })
}

resource "aws_secretsmanager_secret" "this" {
  name        = local.secret_name
  description = "PostgreSQL credentials for ${var.name_prefix}"

  tags = merge(var.tags, {
    Name = local.secret_name
  })
}

resource "aws_secretsmanager_secret_version" "current" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    engine       = "postgres"
    host         = aws_db_instance.this.address
    port         = aws_db_instance.this.port
    username     = var.username
    password     = local.password
    dbname       = var.db_name
    database_url = local.connection_url
  })
}
