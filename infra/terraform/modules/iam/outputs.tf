output "role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "role_name" {
  description = "Name of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "role_id" {
  description = "ID of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution.id
}
