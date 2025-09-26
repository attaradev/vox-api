output "security_group_id" {
  description = "ID of the ECS Security Group"
  value       = aws_security_group.ecs.id
}
