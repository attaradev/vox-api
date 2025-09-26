output "cluster_id" {
  value       = aws_ecs_cluster.this.id
  description = "ID of the ECS cluster"
}

output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "Name of the ECS cluster"
}

output "service_name" {
  value       = aws_ecs_service.this.name
  description = "Name of the ECS service"
}

output "task_execution_role_arn" {
  value       = aws_iam_role.execution.arn
  description = "ARN of the ECS task execution role"
}

output "task_role_arn" {
  value       = aws_iam_role.task.arn
  description = "ARN of the ECS task role"
}

output "task_definition_family" {
  value       = aws_ecs_task_definition.this.family
  description = "ECS task definition family name"
}

output "alb_arn" {
  value       = aws_lb.this.arn
  description = "ARN of the Application Load Balancer"
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "DNS name of the ALB"
}

output "alb_zone_id" {
  value       = aws_lb.this.zone_id
  description = "Hosted zone ID associated with the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ARN of the ALB target group"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "CloudWatch log group for container logs"
}

output "access_log_bucket_name" {
  value       = aws_s3_bucket.access_logs.bucket
  description = "S3 bucket receiving ALB access logs"
}
