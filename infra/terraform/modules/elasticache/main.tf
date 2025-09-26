resource "aws_elasticache_subnet_group" "redis" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.cluster_id
  description                = "Redis replication group for ${var.cluster_id}"
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_nodes
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  engine                     = "redis"
  engine_version             = "7.0"
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = var.security_group_ids
  apply_immediately          = true
  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-04:00"
  tags = merge(var.tags, {
    Name = var.cluster_id
  })
}
