variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the ECS cluster"
  type = map(object({
    base   = optional(number)
    name   = optional(string)
    weight = optional(number)
  }))
  default = null
}

variable "tags" {
  description = "Tags to apply to the ECS cluster"
  type        = map(string)
  default     = {}
}
