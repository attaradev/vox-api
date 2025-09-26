variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "inline_policy_json" {
  description = "JSON policy for custom inline permissions attached to ECS task execution role"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}
