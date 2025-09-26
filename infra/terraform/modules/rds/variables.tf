variable "name_prefix" {
  description = "Prefix used for naming RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "voxapi"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "voxapi"
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "allocated_storage" {
  description = "Initial storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaling storage in GB"
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Backup window (UTC)"
  type        = string
  default     = "02:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Maintenance window (UTC)"
  type        = string
  default     = "Sun:03:00-Sun:05:00"
}

variable "multi_az" {
  description = "Create a standby in another AZ"
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key for storage encryption"
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention" {
  description = "Performance Insights retention (7 or 731 days)"
  type        = number
  default     = 7
}

variable "apply_immediately" {
  description = "Apply modifications immediately"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "secret_name" {
  description = "Name for AWS Secrets Manager secret storing database credentials"
  type        = string
  default     = ""
}

variable "existing_master_password" {
  description = "Optional existing master password; leave unset to generate"
  type        = string
  default     = ""
  sensitive   = true
}

variable "password_length" {
  description = "Length of generated password"
  type        = number
  default     = 32
}
