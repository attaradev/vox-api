variable "db_security_group_id" {
  description = "Security group ID for RDS/Postgres (from networking module)"
  type        = string
}

variable "redis_security_group_id" {
  description = "Security group ID for Redis (from networking module)"
  type        = string
}
variable "db_allocated_storage" {
  description = "Allocated storage for the Postgres instance (GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "17.4"
}

variable "db_instance_class" {
  description = "Instance class for the Postgres instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_parameter_group_name" {
  description = "Parameter group name for the Postgres instance"
  type        = string
  default     = ""
}

variable "db_publicly_accessible" {
  description = "Whether the Postgres instance is publicly accessible"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on Postgres deletion"
  type        = bool
  default     = true
}

variable "db_final_snapshot_identifier" {
  description = "Identifier to use for the final DB snapshot when skip_final_snapshot is false. Required when skip_final_snapshot = false."
  type        = string
  default     = ""
  validation {
    condition     = var.db_skip_final_snapshot || (trim(var.db_final_snapshot_identifier) != "")
    error_message = "db_final_snapshot_identifier must be provided when db_skip_final_snapshot is false"
  }
}

variable "redis_node_type" {
  description = "Node type for Redis cluster"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters for Redis"
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover for Redis"
  type        = bool
  default     = false
}
variable "db_name" {
  description = "Name of the Postgres database"
  type        = string
}

variable "db_username" {
  description = "Username for the Postgres database"
  type        = string
}

variable "db_password" {
  description = "Password for the Postgres database"
  type        = string
  sensitive   = true
}


variable "db_subnet_group_name" {
  description = "Subnet group name for the Postgres instance"
  type        = string
}
variable "redis_auth_token" {
  description = "Auth token for Redis cluster (Elasticache)"
  type        = string
}

variable "redis_subnet_group_name" {
  description = "Subnet group name for Redis cluster"
  type        = string
}
variable "project" {
  description = "Project name used for global/shared resources like ECR"
  type        = string
}
variable "name_prefix" {
  description = "Base name applied to all storage resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to created resources"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow Terraform to destroy S3 buckets even when not empty"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "create_alb_log_bucket" {
  description = "Provision a dedicated bucket for ALB access logs"
  type        = bool
  default     = true
}

variable "alb_log_force_destroy" {
  description = "Allow destruction of the ALB log bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "alb_log_kms_key_arn" {
  description = "Optional customer-managed KMS key ARN for ALB log bucket encryption"
  type        = string
  default     = ""
}

variable "ecr_repository_name" {
  description = "Optional override for the ECR repository name"
  type        = string
  default     = ""
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability setting"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable on-push scanning for the repository"
  type        = bool
  default     = true
}

variable "ecr_encryption_type" {
  description = "Repository encryption type"
  type        = string
  default     = "AES256"
}

variable "ecr_encryption_kms_key" {
  description = "Customer-managed KMS key ARN when encryption type is KMS"
  type        = string
  default     = ""
}

variable "ecr_lifecycle_policy_json" {
  description = "Optional JSON lifecycle policy for the repository"
  type        = string
  default     = ""
}

variable "ssm_parameter_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt SSM parameters created in this module"
  type        = string
  default     = ""
}

variable "bucket_suffix_override" {
  description = "Optional override for the bucket suffix (useful for migrations or reproducible names)"
  type        = string
  default     = ""
}

variable "bucket_suffix_length" {
  description = "Number of hex chars to use from the md5-derived suffix"
  type        = number
  default     = 8
}
