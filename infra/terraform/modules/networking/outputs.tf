output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "Security group ID for RDS/Postgres"
}

output "redis_security_group_id" {
  value       = aws_security_group.redis.id
  description = "Security group ID for Redis"
}
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "Security group ID for ALB"
}

output "ecs_security_group_id" {
  value       = aws_security_group.ecs.id
  description = "Security group ID for ECS tasks"
}
output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID of the created VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.this.cidr_block
  description = "CIDR block of the VPC"
}

output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "IDs of the public subnets"
}

output "private_app_subnet_ids" {
  value       = [for subnet in aws_subnet.private_app : subnet.id]
  description = "IDs of the private application subnets"
}

output "private_data_subnet_ids" {
  value       = [for subnet in aws_subnet.private_data : subnet.id]
  description = "IDs of the private data subnets"
}

output "db_subnet_group_name" {
  value       = aws_db_subnet_group.this.name
  description = "RDS DB subnet group name"
}

output "redis_subnet_group_name" {
  value       = aws_elasticache_subnet_group.this.name
  description = "ElastiCache subnet group name"
}

output "endpoint_security_group_id" {
  value       = try(aws_security_group.endpoints[0].id, null)
  description = "Security group ID attached to VPC interface endpoints"
}

output "availability_zones" {
  value       = var.availability_zones
  description = "Availability zones used by the network"
}

// ...existing code...
