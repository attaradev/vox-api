variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs for RDS"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
}
