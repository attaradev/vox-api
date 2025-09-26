variable "name_prefix" {
  description = "Prefix used for cache resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ElastiCache subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups permitted to connect to Redis"
  type        = list(string)
  default     = []
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "Instance type for cache nodes"
  type        = string
  default     = "cache.t3.medium"
}

variable "replicas_per_node_group" {
  description = "Number of replicas per node group"
  type        = number
  default     = 1
}

variable "num_node_groups" {
  description = "Number of node groups (shards)"
  type        = number
  default     = 1
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to cache resources"
  type        = map(string)
  default     = {}
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "Sun:05:00-Sun:06:00"
}

variable "snapshot_window" {
  description = "Snapshot window"
  type        = string
  default     = "04:00-05:00"
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 7
}
