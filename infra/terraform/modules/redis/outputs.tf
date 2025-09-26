output "primary_endpoint" {
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
  description = "Primary endpoint address for Redis"
}

output "reader_endpoint" {
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
  description = "Reader endpoint address for Redis"
}

output "port" {
  value       = aws_elasticache_replication_group.this.port
  description = "Redis port"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group protecting Redis"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "ARN of the Redis credentials secret"
}
