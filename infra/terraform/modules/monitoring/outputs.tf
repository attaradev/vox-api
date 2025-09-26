
output "celery_log_group_name" {
  value       = aws_cloudwatch_log_group.celery.name
  description = "Name of the CloudWatch log group for celery workers"
}

output "ecs_service_log_group_name" {
  value       = aws_cloudwatch_log_group.ecs_service.name
  description = "Name of the CloudWatch log group for ECS service"
}

output "ecs_cpu_high_alarm_name" {
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name
  description = "Name of the ECS high CPU alarm"
}

output "ecs_unhealthy_alarm_name" {
  value       = aws_cloudwatch_metric_alarm.ecs_unhealthy.alarm_name
  description = "Name of the ECS unhealthy tasks alarm"
}
