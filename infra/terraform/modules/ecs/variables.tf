variable "cpu" {
  description = "CPU units for ECS task definition"
  type        = string
}
variable "execution_role_arn" {
  description = "IAM execution role ARN for ECS task definition"
  type        = string
  default     = ""
}
variable "aws_region" {
  description = "AWS region for log configuration"
  type        = string
}

variable "family" {
  description = "Family name for ECS task definition"
  type        = string
}

variable "ecs_log_group_name" {
  description = "Name of the CloudWatch log group for ECS service"
  type        = string
}

variable "ecs_cpu_high_alarm_name" {
  description = "Name of the ECS high CPU alarm"
  type        = string
}

variable "ecs_unhealthy_alarm_name" {
  description = "Name of the ECS unhealthy tasks alarm"
  type        = string
}


variable "name_prefix" {
  description = "Base name used for ECS resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets where ECS tasks will run"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets for the Application Load Balancer"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID assigned to the ALB"
  type        = string
}

variable "service_security_group_id" {
  description = "Security group ID assigned to ECS tasks"
  type        = string
}

variable "container_image" {
  description = "Container image for the ECS task"
  type        = string
}

variable "image_tag" {
  description = "Optional image tag (short sha) provided by CI. If provided, and container_image is not a full image, module will construct full image using account/reg and ecr_repository_name or name_prefix."
  type        = string
  default     = ""
}

variable "ecr_repository_name" {
  description = "Optional ECR repository name to compose image URI when only image_tag is provided. Falls back to name_prefix if empty."
  type        = string
  default     = ""
}

variable "enable_https_listener" {
  description = "Whether to create an HTTPS listener and redirect HTTP traffic when a certificate is supplied"
  type        = bool
  default     = false
}

variable "container_port" {
  description = "Container port exposed by the service"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path used by the ALB target group health check"
  type        = string
  default     = "/healthz"
}

variable "container_health_command" {
  description = "Custom health check command for the application container"
  type        = list(string)
  default     = []
}

variable "container_health_interval" {
  description = "Seconds between container health checks"
  type        = number
  default     = 30
}

variable "container_health_timeout" {
  description = "Timeout in seconds for container health checks"
  type        = number
  default     = 5
}

variable "container_health_retries" {
  description = "Number of consecutive failures before container is marked unhealthy"
  type        = number
  default     = 3
}

variable "container_health_start_period" {
  description = "Grace period in seconds before starting container health checks"
  type        = number
  default     = 180
}

variable "ecs_health_check_grace_period_seconds" {
  description = "Grace period for ECS service health checks"
  type        = number
  default     = 300
}

variable "desired_count" {
  description = "Number of desired ECS tasks"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory (MB) for the Fargate task"
  type        = number
  default     = 1024
}

variable "assign_public_ip" {
  description = "Whether ECS tasks receive public IPs"
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention period for the service log group"
  type        = number
  default     = 30
}

variable "environment" {
  description = "Environment variables injected into the container"
  type        = map(string)
  default     = {}
}

variable "environment_secrets" {
  description = "Map of environment variable names to SSM parameter names or ARNs. Values may be full ARN or a parameter name (with or without leading /)."
  type        = map(string)
  default     = {}
}

variable "celery_desired_count" {
  description = "Desired number of Celery worker tasks (0 disables the Celery service)"
  type        = number
  default     = 0
}

variable "celery_cpu" {
  description = "CPU units allocated to the Celery worker task definition"
  type        = number
  default     = 512
}

variable "celery_memory" {
  description = "Memory (MiB) allocated to the Celery worker task definition"
  type        = number
  default     = 1024
}

variable "celery_command" {
  description = "Command override for the Celery worker container"
  type        = list(string)
  default     = ["celery", "-A", "vox_api", "worker", "--loglevel=info"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (optional - if provided, HTTPS listener will be created)"
  type        = string
  default     = ""
}

variable "scale_min_capacity" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 2
}

variable "scale_max_capacity" {
  description = "Maximum number of tasks for autoscaling"
  type        = number
  default     = 6
}

variable "scale_cpu_target" {
  description = "Target CPU utilization percentage for autoscaling"
  type        = number
  default     = 60
}

variable "scale_memory_target" {
  description = "Target memory utilization percentage for autoscaling"
  type        = number
  default     = 75
}

variable "task_role_policy_arns" {
  description = "Map of IAM policies to attach to the task role (key is descriptive name)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to propagate to ECS resources"
  type        = map(string)
  default     = {}
}


variable "celery_environment_overrides" {
  description = "Additional environment variables applied to the Celery worker container"
  type        = map(string)
  default     = {}
}
