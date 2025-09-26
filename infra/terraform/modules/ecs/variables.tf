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

variable "container_port" {
  description = "Container port exposed by the service"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path used by the ALB target group health check"
  type        = string
  default     = "/"
}

variable "desired_count" {
  description = "Number of desired ECS tasks"
  type        = number
  default     = 2
}

// ...existing code...

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
