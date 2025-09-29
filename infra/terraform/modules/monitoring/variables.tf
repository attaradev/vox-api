
variable "celery_log_group_name" {
  description = "Name of the CloudWatch log group for celery workers"
  type        = string
}

variable "celery_log_retention_in_days" {
  description = "Retention period for celery log group"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to monitoring resources"
  type        = map(string)
  default     = {}
}

variable "ecs_service_log_group_name" {
  description = "Name of the CloudWatch log group for ECS service"
  type        = string
}

variable "ecs_service_log_retention_in_days" {
  description = "Retention period for ECS service log group"
  type        = number
  default     = 30
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "ecs_cpu_alarm_threshold" {
  description = "CPU utilization threshold for ECS alarm"
  type        = number
  default     = 80
}

variable "namespace" {
  description = "CloudWatch metric namespace to use for ECS metrics"
  type        = string
  default     = "AWS/ECS"
}
