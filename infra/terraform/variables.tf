variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project tag and naming seed"
  type        = string
  default     = "vox"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "short_environment" {
  description = "Short environment identifier used for naming (dev, stg, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = can(regex("^(dev|stg|prod|qa|stage|production|staging)$", var.short_environment))
    error_message = "short_environment must be one of: dev, stg, prod, qa, stage, staging, production"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Optional list of AZs to use; defaults to the first two available"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "Optional list of CIDRs for public subnets"
  type        = list(string)
  default     = []
}

variable "private_app_subnet_cidrs" {
  description = "Optional list of CIDRs for application subnets"
  type        = list(string)
  default     = []
}

variable "private_data_subnet_cidrs" {
  description = "Optional list of CIDRs for data subnets"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway across availability zones to reduce cost"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_logs_log_group_name" {
  description = "Existing CloudWatch log group name for flow logs (leave blank to create)"
  type        = string
  default     = ""
}

variable "flow_logs_retention_in_days" {
  description = "Retention period for VPC flow logs"
  type        = number
  default     = 30
}

variable "create_vpc_endpoints" {
  description = "Create common VPC endpoints for private connectivity"
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path used for ALB and container health checks"
  type        = string
  default     = "/healthz"
}

variable "container_image" {
  description = "Optional full URI to the container image for the API service"
  type        = string
  default     = ""
}

variable "alb_allowed_cidrs" {
  description = "CIDR ranges allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https_listener" {
  description = "Enable an HTTPS listener (requires certificate_arn)"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN used when enable_https_listener is true"
  type        = string
  default     = ""
}

/* Removed: existing_alb_log_bucket_name - Terraform will manage ALB log bucket when create_alb_log_bucket is true. */

variable "s3_force_destroy" {
  description = "Allow Terraform to destroy S3 buckets even when they are not empty"
  type        = bool
  default     = false
}

variable "s3_versioning_enabled" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "create_alb_log_bucket" {
  description = "Create a dedicated S3 bucket for ALB access logs"
  type        = bool
  default     = true
}

variable "alb_log_force_destroy" {
  description = "Allow destroying the ALB log bucket even when objects are present"
  type        = bool
  default     = false
}

variable "alb_log_kms_key_arn" {
  description = "Optional KMS key ARN for encrypting ALB access logs"
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
  description = "ECR encryption type"
  type        = string
  default     = "AES256"
}

variable "ecr_encryption_kms_key" {
  description = "KMS key ARN used when ecr_encryption_type is KMS"
  type        = string
  default     = ""
}

variable "ecr_lifecycle_policy_json" {
  description = "Optional JSON lifecycle policy for the repository"
  type        = string
  default     = ""
}

variable "ecs_desired_count" {
  description = "Desired ECS task count"
  type        = number
  default     = 2
}

variable "ecs_cpu" {
  description = "CPU units for each ECS task"
  type        = number
  default     = 512
}

variable "ecs_memory" {
  description = "Memory (MiB) for each ECS task"
  type        = number
  default     = 1024
}

variable "ecs_task_environment" {
  description = "Additional environment variables injected into the ECS task"
  type        = map(string)
  default     = {}
}

variable "ecs_execution_managed_policy_arns" {
  description = "Managed policies to attach to the ECS execution role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

variable "ecs_task_role_policy_arns" {
  description = "Managed policies to attach to the ECS task role"
  type        = list(string)
  default     = []
}

variable "ecs_task_inline_policies" {
  description = "Additional inline policy documents (JSON) to attach to the ECS task role"
  type        = map(string)
  default     = {}
}

variable "ecs_log_retention_in_days" {
  description = "Log retention period for ECS log groups"
  type        = number
  default     = 30
}

variable "ecs_scale_min_capacity" {
  description = "Minimum task count for autoscaling"
  type        = number
  default     = 2
}

variable "ecs_scale_max_capacity" {
  description = "Maximum task count for autoscaling"
  type        = number
  default     = 6
}

variable "ecs_scale_cpu_target" {
  description = "Target CPU utilization for autoscaling"
  type        = number
  default     = 60
}

variable "ecs_scale_memory_target" {
  description = "Target memory utilization for autoscaling"
  type        = number
  default     = 75
}

variable "ssm_parameter_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt SSM parameters"
  type        = string
  default     = ""
}

variable "celery_cpu" {
  description = "CPU units for Celery workers"
  type        = number
  default     = 512
}

variable "celery_memory" {
  description = "Memory (MiB) for Celery workers"
  type        = number
  default     = 1024
}

variable "celery_desired_count" {
  description = "Desired Celery worker count"
  type        = number
  default     = 1
}

variable "db_name" {
  description = "Name of the application database"
  type        = string
  default     = "voxapi"
}

variable "db_username" {
  description = "Master username for Postgres"
  type        = string
  default     = "voxapi"
}

variable "db_engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "17.4"
}

variable "db_instance_class" {
  description = "Instance class for Postgres"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Initial storage size for Postgres"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum autoscaling storage for Postgres"
  type        = number
  default     = 50
}

variable "db_backup_retention_period" {
  description = "Backup retention in days for Postgres"
  type        = number
  default     = 7
}

variable "db_preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "02:00-04:00"
}

variable "db_preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Sun:05:00-Sun:07:00"
}

variable "db_multi_az" {
  description = "Provision multi-AZ Postgres standby"
  type        = bool
  default     = false
}

variable "db_storage_encrypted" {
  description = "Enable storage encryption for Postgres"
  type        = bool
  default     = true
}

variable "db_kms_key_id" {
  description = "KMS key used to encrypt Postgres"
  type        = string
  default     = ""
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_performance_insights_retention" {
  description = "Performance Insights retention (7 or 731 days)"
  type        = number
  default     = 7
}

variable "db_auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "db_apply_immediately" {
  description = "Apply modifications immediately"
  type        = bool
  default     = false
}

/* Removed: db_existing_password - Terraform now always manages the DB password via random_password.db */

variable "db_additional_allowed_security_group_ids" {
  description = "Additional security groups allowed to access the database"
  type        = list(string)
  default     = []
}

variable "redis_manage_replication_group" {
  description = "Whether Terraform manages the Redis replication group"
  type        = bool
  default     = true
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "Redis node instance type"
  type        = string
  default     = "cache.t4g.small"
}

variable "redis_replicas_per_node_group" {
  description = "Number of replicas per node group"
  type        = number
  default     = 1
}

variable "redis_num_node_groups" {
  description = "Number of node groups"
  type        = number
  default     = 1
}

variable "redis_maintenance_window" {
  description = "Preferred maintenance window for Redis"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "redis_snapshot_window" {
  description = "Preferred snapshot window for Redis"
  type        = string
  default     = "03:00-04:00"
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 7
}

variable "stripe_secret_key" {
  description = "Stripe API secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "frontend_url" {
  description = "Public URL of the frontend"
  type        = string
  default     = ""
}

variable "email_domain" {
  description = "Domain verified for SES"
  type        = string
  default     = "attara.dev"
}

variable "create_ses_smtp_credentials" {
  description = "Create IAM SMTP credentials for SES"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "Alarm action ARNs"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "OK action ARNs"
  type        = list(string)
  default     = []
}

variable "insufficient_data_actions" {
  description = "Actions for insufficient data state"
  type        = list(string)
  default     = []
}

variable "monitoring_cpu_high_threshold" {
  description = "CPU utilization percentage that triggers an alarm"
  type        = number
  default     = 85
}

variable "monitoring_unhealthy_host_threshold" {
  description = "Number of unhealthy hosts that triggers an alarm"
  type        = number
  default     = 1
}

variable "monitoring_evaluation_periods" {
  description = "Evaluation periods for monitoring alarms"
  type        = number
  default     = 2
}

variable "monitoring_period" {
  description = "Alarm evaluation period in seconds"
  type        = number
  default     = 60
}
