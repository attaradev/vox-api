output "static_bucket_name" {
  value       = aws_s3_bucket.static.bucket
  description = "Name of the static assets bucket"
}

output "media_bucket_name" {
  value       = aws_s3_bucket.media.bucket
  description = "Name of the media uploads bucket"
}

output "alb_logs_bucket_name" {
  value       = try(aws_s3_bucket.alb_logs[0].bucket, null)
  description = "Name of the ALB access logs bucket"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repository URL for application images"
}

output "ecr_repository_arn" {
  value       = aws_ecr_repository.app.arn
  description = "ARN of the application ECR repository"
}

output "database_url_ssm_name" {
  value       = aws_ssm_parameter.database_url.name
  description = "Name of the SSM parameter storing the database URL"
}


output "stripe_webhook_secret" {
  value       = random_password.stripe_webhook_secret.result
  description = "Generated Stripe webhook secret"
}

output "django_secret_key_ssm_name" {
  value       = aws_ssm_parameter.django_secret_key.name
  description = "SSM parameter name that stores the Django secret key"
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "PostgreSQL endpoint"
}

output "rds_port" {
  value       = aws_db_instance.postgres.port
  description = "PostgreSQL port"
}

output "rds_dbname" {
  value       = aws_db_instance.postgres.db_name
  description = "PostgreSQL database name"
}

output "rds_username" {
  value       = aws_db_instance.postgres.username
  description = "PostgreSQL username"
}

output "rds_password" {
  value       = aws_db_instance.postgres.password
  description = "PostgreSQL password"
  sensitive   = true
}

output "rds_security_group_id" {
  value       = tolist(aws_db_instance.postgres.vpc_security_group_ids)[0]
  description = "Security group protecting the database"
}

output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Primary endpoint for Redis"
}

output "redis_auth_token" {
  value       = aws_elasticache_replication_group.redis.auth_token
  description = "Redis authentication token"
  sensitive   = true
}

output "redis_security_group_id" {
  value       = tolist(aws_elasticache_replication_group.redis.security_group_ids)[0]
  description = "Security group protecting Redis"
}
