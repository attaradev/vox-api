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

variable "create_service_discovery_namespace" {
  description = "Whether to create a private Service Discovery (Cloud Map) namespace for this service"
  type        = bool
  default     = false
}

variable "service_discovery_namespace_name" {
  description = "If create_service_discovery_namespace is true, the DNS name for the private namespace (e.g. example.internal)"
  type        = string
  default     = ""
}

variable "service_discovery_namespace_id" {
  description = "If provided, use this existing service discovery namespace id instead of creating a new one"
  type        = string
  default     = ""
}

variable "service_discovery_dns_record_ttl" {
  description = "TTL for created Cloud Map DNS records"
  type        = number
  default     = 60
}

variable "environment_name" {
  description = "Short environment name (e.g., production, staging) used for naming resources like service discovery namespace"
  type        = string
  default     = "production"
}

variable "short_environment" {
  description = "Short environment identifier (e.g., prod, stg, dev). Falls back to var.environment_name if empty."
  type        = string
  default     = ""
}

variable "target_group_deregistration_delay" {
  description = "Seconds to wait for connection draining when a target is deregistered from the ALB target group"
  type        = number
  default     = 120
}

variable "target_group_slow_start" {
  description = "Optional slow start duration for new targets in seconds. 0 disables slow start."
  type        = number
  default     = 0
}

variable "target_group_stickiness_enabled" {
  description = "Enable target group stickiness (session affinity)."
  type        = bool
  default     = false
}

variable "target_group_stickiness_lb_cookie_duration" {
  description = "Duration in seconds for the ALB cookie-based stickiness when enabled."
  type        = number
  default     = 86400
}

variable "use_host_port" {
  description = "Whether to set hostPort equal to containerPort. For Fargate it is recommended to keep hostPort = 0 (ephemeral)."
  type        = bool
  default     = false
}

variable "enable_alb_request_count_scaling" {
  description = "Enable Application Load Balancer Request Count per Target autoscaling policy."
  type        = bool
  default     = true
}

variable "alb_request_count_target" {
  description = "Target requests per second per target for ALB request-count scaling."
  type        = number
  default     = 100
}
