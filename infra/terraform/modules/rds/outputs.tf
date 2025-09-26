output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.db_instance_identifier
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.db_instance_port
}
