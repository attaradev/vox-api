output "vpc_id" {
  value       = module.network.vpc_id
  description = "ID of the provisioned VPC"
}

output "public_subnet_ids" {
  value       = module.network.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_app_subnet_ids" {
  value       = module.network.private_app_subnet_ids
  description = "Private application subnet IDs"
}

output "private_data_subnet_ids" {
  value       = module.network.private_data_subnet_ids
  description = "Private data subnet IDs"
}

output "alb_dns_name" {
  value       = module.ecs_service.alb_dns_name
  description = "DNS name for the Application Load Balancer"
}

output "alb_hosted_zone_id" {
  value       = module.ecs_service.alb_zone_id
  description = "Hosted zone ID for ALB DNS records"
}

output "ecs_cluster_name" {
  value       = module.ecs_service.cluster_name
  description = "Name of the ECS cluster"
}

output "ecs_service_name" {
  value       = module.ecs_service.service_name
  description = "Name of the ECS service"
}

output "ecs_task_family" {
  value       = module.ecs_service.task_definition_family
  description = "Task definition family name for the ECS service"
}

output "celery_service_name" {
  value       = aws_ecs_service.celery.name
  description = "Name of the Celery ECS service"
}

output "celery_task_family" {
  value       = aws_ecs_task_definition.celery.family
  description = "Task definition family name for the Celery service"
}

output "db_endpoint" {
  value       = module.rds.endpoint
  description = "Postgres endpoint"
}

output "db_secret_arn" {
  value       = module.rds.secret_arn
  description = "Secrets Manager ARN with Postgres credentials"
}

output "redis_primary_endpoint" {
  value       = module.redis.primary_endpoint
  description = "Primary endpoint for Redis"
}

output "redis_secret_arn" {
  value       = module.redis.secret_arn
  description = "Secrets Manager ARN with Redis auth token"
}

output "static_bucket_name" {
  value       = module.s3_buckets.static_bucket_name
  description = "Static assets bucket"
}

output "media_bucket_name" {
  value       = module.s3_buckets.media_bucket_name
  description = "Media uploads bucket"
}

output "django_secret_arn" {
  value       = aws_secretsmanager_secret.django.arn
  description = "Secrets Manager ARN for Django settings"
}

output "alb_access_logs_bucket" {
  value       = module.ecs_service.access_log_bucket_name
  description = "S3 bucket receiving ALB access logs"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URI for the Vox API ECR repository"
}

output "ecr_repository_arn" {
  value       = module.ecr.repository_arn
  description = "ARN of the Vox API ECR repository"
}
