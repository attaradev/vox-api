output "static_bucket_name" {
  description = "Static assets bucket"
  value       = module.storage.static_bucket_name
}

output "media_bucket_name" {
  description = "Media uploads bucket"
  value       = module.storage.media_bucket_name
}

output "ecr_repository_url" {
  description = "URI for the application ECR repository"
  value       = module.storage.ecr_repository_url
}

output "ecr_repository_name" {
  description = "Name of the application ECR repository"
  value       = module.storage.ecr_repository_name
}

output "ecr_repository_arn" {
  description = "ARN of the application ECR repository"
  value       = module.storage.ecr_repository_arn
}

output "celery_service_name" {
  description = "Name of the Celery ECS service"
  value       = try(module.ecs.celery_service_name, null)
}

output "celery_task_family" {
  description = "Task definition family for the Celery ECS task"
  value       = try(module.ecs.celery_task_definition_family, null)
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = try(module.ecs.cluster_name, null)
}

output "ecs_service_name" {
  description = "Name of the primary ECS service"
  value       = try(module.ecs.service_name, null)
}

output "ecs_task_family" {
  description = "Task definition family for the primary ECS task"
  value       = try(module.ecs.task_definition_family, null)
}

output "database_url_ssm_name" {
  description = "SSM parameter name that stores the DATABASE_URL for the application"
  value       = module.storage.database_url_ssm_name
}

output "postgres_password_ssm_name" {
  description = "SSM parameter that stores the Postgres password"
  value       = module.storage.postgres_password_ssm_name
}

output "django_secret_key_ssm_name" {
  description = "SSM parameter name that stores the Django secret key"
  value       = module.storage.django_secret_key_ssm_name
}

output "redis_primary_endpoint" {
  description = "Primary Redis endpoint address"
  value       = module.storage.redis_primary_endpoint
}

output "redis_auth_token" {
  description = "Redis auth token (sensitive)"
  value       = module.storage.redis_auth_token
  sensitive   = true
}

output "redis_auth_token_ssm_name" {
  description = "SSM parameter that stores the Redis auth token"
  value       = module.storage.redis_auth_token_ssm_name
}

output "redis_url_ssm_name" {
  description = "SSM parameter that stores the Redis URL"
  value       = module.storage.redis_url_ssm_name
}

output "celery_broker_url_ssm_name" {
  description = "SSM parameter that stores the Celery broker URL"
  value       = module.storage.celery_broker_url_ssm_name
}

output "celery_result_backend_ssm_name" {
  description = "SSM parameter that stores the Celery result backend URL"
  value       = module.storage.celery_result_backend_ssm_name
}

output "stripe_webhook_secret" {
  description = "Stripe webhook signing secret (sensitive)"
  value       = module.storage.stripe_webhook_secret
  sensitive   = true
}

output "stripe_webhook_secret_ssm_name" {
  description = "SSM parameter that stores the Stripe webhook secret"
  value       = module.storage.stripe_webhook_secret_ssm_name
}

output "stripe_secret_key_ssm_name" {
  description = "SSM parameter that stores the Stripe API secret key (if provided)"
  value       = module.storage.stripe_secret_key_ssm_name
}

output "application_environment" {
  description = "Map of non-sensitive environment entries for the application (for CI usage)."
  value       = local.application_environment_plain
}

output "application_environment_secrets" {
  description = "Map of sensitive environment variable names to the SSM parameters that store their values."
  value       = local.application_environment_secrets
}
