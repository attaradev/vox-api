
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

output "ecr_repository_arn" {
  description = "ARN of the application ECR repository"
  value       = module.storage.ecr_repository_arn
}

output "celery_service_name" {
  description = "Name of the Celery ECS service"
  # Celery service is optional; modules/ecs may not provision a separate celery service.
  # Provide a null fallback so downstream CI can handle absence gracefully.
  value = try(module.ecs.celery_service_name, null)
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

output "stripe_webhook_secret" {
  description = "Stripe webhook signing secret (sensitive)"
  value       = module.storage.stripe_webhook_secret
  sensitive   = true
}

# A compact map of non-sensitive environment values that the application needs.
# This intentionally excludes raw secrets (DB password, Redis auth token, stripe secret)
output "application_environment" {
  description = "JSON-like map of non-sensitive environment entries for the application (for CI usage). Excludes passwords and tokens."
  value = {
    for k, v in local.ecs_environment : k => v
    if !(k == "REDIS_PASSWORD" || k == "POSTGRES_PASSWORD" || k == "CELERY_BROKER_URL" || k == "CELERY_RESULT_BACKEND")
  }
}
