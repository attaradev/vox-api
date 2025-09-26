locals {
  auth_token       = random_password.auth.result
  secret_name      = "${var.name_prefix}-redis-auth"
  redis_url        = "rediss://:${urlencode(local.auth_token)}@${aws_elasticache_replication_group.this.primary_endpoint_address}:${aws_elasticache_replication_group.this.port}/0"
  redis_reader_url = "rediss://:${urlencode(local.auth_token)}@${aws_elasticache_replication_group.this.reader_endpoint_address}:${aws_elasticache_replication_group.this.port}/0"
}

resource "random_password" "auth" {
  length  = 32
  special = false
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-redis-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-subnet-group"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-redis"
  description = "Controls access to Redis"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis"
  })
}

resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, sg_id in var.allowed_security_group_ids : tostring(idx) => sg_id }

  description              = "Allow Redis from trusted security group"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = each.value
}

resource "aws_elasticache_replication_group" "this" {
  description                = "Redis replication group for ${var.name_prefix}"
  replication_group_id       = "${var.name_prefix}-redis"
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  num_node_groups            = var.num_node_groups
  replicas_per_node_group    = var.replicas_per_node_group
  port                       = 6379
  parameter_group_name       = null
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = local.auth_token
  apply_immediately          = false
  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window
  snapshot_retention_limit   = var.snapshot_retention_limit

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis"
  })
}

resource "aws_secretsmanager_secret" "this" {
  name        = local.secret_name
  description = "Redis auth token for ${var.name_prefix}"

  tags = merge(var.tags, {
    Name = local.secret_name
  })
}

resource "aws_secretsmanager_secret_version" "current" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    host             = aws_elasticache_replication_group.this.primary_endpoint_address
    port             = aws_elasticache_replication_group.this.port
    auth_token       = local.auth_token
    reader_endpoint  = aws_elasticache_replication_group.this.reader_endpoint_address
    redis_url        = local.redis_url
    redis_reader_url = local.redis_reader_url
  })
}
