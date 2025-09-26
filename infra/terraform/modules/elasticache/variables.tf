variable "cluster_id" {
  description = "Redis cluster ID"
  type        = string
}

variable "node_type" {
  description = "Instance type for Redis nodes"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 1
}

variable "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Redis"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for Redis"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to ElastiCache resources"
  type        = map(string)
  default     = {}
}
