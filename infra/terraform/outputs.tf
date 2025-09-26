output "alb_ip_addresses" {
  description = "List of IP addresses for the Application Load Balancer (for DNS/domain setup)"
  value       = module.alb.alb_ip_addresses
}

output "ecr_repository_url" {
  description = "ECR repository URL for the app image"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs.ecs_cluster_id
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}
