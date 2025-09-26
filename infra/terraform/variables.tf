variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "vox-api-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "vox-api-ecs-cluster"
}

variable "asg_sg_name" {
  description = "Security group name for ECS tasks"
  type        = string
  default     = "vox-api-ecs-sg"
}

variable "asg_allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for ECS SG ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "vox-api-alb"
}

variable "alb_target_group_name" {
  description = "Name of the ALB target group"
  type        = string
  default     = "vox-api-alb-tg"
}

variable "alb_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = "vox-api-logs"
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for ECS logs"
  type        = string
  default     = "vox-api-ecs-logs"
}

variable "cloudwatch_kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = ""
}

variable "elasticache_cluster_id" {
  description = "Redis replication group ID"
  type        = string
  default     = "vox-api-redis-cluster"
}

variable "elasticache_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 1
}

variable "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  type        = string
  default     = "vox-api-redis-subnet-group"
}

variable "elasticache_subnet_ids" {
  description = "Subnet IDs for Redis"
  type        = list(string)
  default     = []
}

variable "elasticache_security_group_ids" {
  description = "Security group IDs for Redis"
  type        = list(string)
  default     = []
}

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "vox-api-rds"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "voxapidb"
}

variable "rds_vpc_security_group_ids" {
  description = "Security group IDs for RDS"
  type        = list(string)
  default     = []
}

variable "rds_subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
  default     = []
}

variable "s3_bucket_name" {
  description = "S3 bucket name for media/static files"
  type        = string
  default     = "vox-api-media"
}

variable "iam_role_name" {
  description = "IAM role name for ECS task execution"
  type        = string
  default     = "vox-api-ecs-task-execution-role"
}

variable "iam_inline_policy_json" {
  description = "Inline policy JSON for IAM role"
  type        = string
  default     = ""
}

variable "asm_secret_name" {
  description = "Secrets Manager secret name for RDS credentials"
  type        = string
  default     = "vox-api-rds-credentials"
}

variable "asm_secret_access_policy_json" {
  description = "Resource policy JSON for ASM secret access"
  type        = string
  default     = ""
}



variable "vpc_flow_log_group_name" {
  description = "CloudWatch log group name for VPC flow logs"
  type        = string
  default     = "vox-api-vpc-flow-logs"
}

variable "vpc_flow_log_role_arn" {
  description = "IAM role ARN for VPC flow logs"
  type        = string
  default     = ""
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for the app image."
  type        = string
  default     = "vox-api"
}

variable "ecs_task_family" {
  description = "ECS task definition family name."
  type        = string
  default     = "vox-api-task"
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task."
  type        = string
  default     = "512"
}

variable "ecs_task_memory" {
  description = "Memory (MB) for ECS task."
  type        = string
  default     = "1024"
}

variable "image_tag" {
  description = "Docker image tag to deploy."
  type        = string
  default     = "latest"
}


variable "ecs_service_name" {
  description = "Name of the ECS service."
  type        = string
  default     = "vox-api-service"
}

variable "ecs_task_execution_policy_arns" {
  description = "List of IAM policy ARNs for ECS task execution role (SSM, Secrets Manager access)."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]
}
