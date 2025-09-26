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

output "endpoint_security_group_id" {
  value       = try(aws_security_group.endpoints[0].id, null)
  description = "Security group ID attached to VPC interface endpoints"
}

output "availability_zones" {
  value       = var.availability_zones
  description = "Availability zones used by the network"
}
