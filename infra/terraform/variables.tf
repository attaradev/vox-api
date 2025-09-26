variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project tag and naming seed"
  type        = string
  default     = "vox-api"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
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
  description = "Optional list of CIDRs for public subnets. Must match the number of AZs when supplied."
  type        = list(string)
  default     = []
}

variable "private_app_subnet_cidrs" {
  description = "Optional list of CIDRs for private subnets that host ECS tasks"
  type        = list(string)
  default     = []
}

variable "private_data_subnet_cidrs" {
  description = "Optional list of CIDRs for private subnets that host data services"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway across availability zones to reduce cost"
  type        = bool
  default     = true
}

variable "container_image" {
  description = "Optional full URI to the container image for the API service"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Application port exposed by the container"
  type        = number
  default     = 8000
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
  description = "Memory (MB) for each ECS task"
  type        = number
  default     = 1024
}

variable "ecs_task_environment" {
  description = "Environment variables injected into the ECS task"
  type        = map(string)
  default     = {}
}

variable "ecs_task_secrets" {
  description = "Secrets injected into the ECS task"
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "ecs_task_role_policy_arns" {
  description = "Additional IAM policies to attach to the ECS task role"
  type        = list(string)
  default     = []
}

variable "ecs_log_retention_in_days" {
  description = "Log retention period for ECS log group"
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
  default     = "17.5"
}

variable "db_instance_class" {
  description = "Instance class for Postgres"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial storage size for Postgres"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum autoscaling storage for Postgres"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "Backup retention in days for Postgres"
  type        = number
  default     = 1
}

variable "db_multi_az" {
  description = "Provision multi-AZ Postgres standby"
  type        = bool
  default     = false
}

variable "db_apply_immediately" {
  description = "Apply RDS changes immediately"
  type        = bool
  default     = false
}

variable "db_existing_password" {
  description = "Optional existing database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_secret_name" {
  description = "Optional override for the Postgres secret name"
  type        = string
  default     = ""
}

variable "db_additional_allowed_security_group_ids" {
  description = "Additional security groups allowed to access Postgres"
  type        = list(string)
  default     = []
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "Redis node instance type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_replicas_per_node_group" {
  description = "Replicas per Redis node group"
  type        = number
  default     = 1
}

variable "redis_num_node_groups" {
  description = "Redis node groups (shards)"
  type        = number
  default     = 1
}

variable "redis_snapshot_retention_limit" {
  description = "Redis snapshot retention days"
  type        = number
  default     = 7
}

variable "redis_maintenance_window" {
  description = "Redis maintenance window"
  type        = string
  default     = "Sun:05:00-Sun:06:00"
}

variable "redis_snapshot_window" {
  description = "Redis snapshot window"
  type        = string
  default     = "04:00-05:00"
}

variable "s3_force_destroy" {
  description = "Allow Terraform to delete non-empty S3 buckets"
  type        = bool
  default     = false
}

variable "ecr_image_tag_mutability" {
  description = "Controls whether image tags can be overwritten (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be MUTABLE or IMMUTABLE"
  }
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push for the ECR repository"
  type        = bool
  default     = true
}

variable "ecr_encryption_type" {
  description = "Encryption type for the ECR repository (AES256 or KMS)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.ecr_encryption_type)
    error_message = "ecr_encryption_type must be AES256 or KMS"
  }
}

variable "ecr_encryption_kms_key" {
  description = "KMS key ARN when using KMS encryption for the ECR repository"
  type        = string
  default     = ""
}

variable "ecr_lifecycle_policy_json" {
  description = "Optional JSON override for the ECR lifecycle policy"
  type        = string
  default     = ""
}

# Celery worker configuration
variable "celery_cpu" {
  description = "CPU units for Celery worker tasks"
  type        = number
  default     = 256
}

variable "celery_memory" {
  description = "Memory for Celery worker tasks"
  type        = number
  default     = 512
}

variable "celery_desired_count" {
  description = "Desired number of Celery worker tasks"
  type        = number
  default     = 1
}

# Infrastructure creation flags
variable "create_shared_resources" {
  description = "Whether to create shared resources like S3 buckets, ECR, etc."
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Whether to create IAM roles for ECS tasks"
  type        = bool
  default     = true
}

variable "create_cloudwatch_log_groups" {
  description = "Whether to create CloudWatch log groups"
  type        = bool
  default     = true
}

variable "create_alb" {
  description = "Whether to create Application Load Balancer"
  type        = bool
  default     = true
}

variable "frontend_url" {
  description = "Frontend URL for password reset links and CORS"
  type        = string
  default     = "https://your-frontend-domain.com"
}
