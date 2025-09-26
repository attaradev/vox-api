output "endpoint" {
  value       = aws_db_instance.this.address
  description = "Writer endpoint for the database"
}

output "port" {
  value       = aws_db_instance.this.port
  description = "Port of the database"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group protecting the database"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "ARN of the Secrets Manager secret containing credentials"
}

output "identifier" {
  value       = aws_db_instance.this.id
  description = "Identifier of the RDS instance"
}
