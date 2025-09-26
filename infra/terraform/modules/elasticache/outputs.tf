output "elasticache_replication_group_id" {
  description = "ID of the ElastiCache Redis replication group"
  value       = aws_elasticache_replication_group.redis.id
}

output "elasticache_endpoint" {
  description = "Primary endpoint of the ElastiCache Redis replication group"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.redis.name
}
