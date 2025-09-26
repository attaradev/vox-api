variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
}

variable "secret_string" {
  description = "Secret string value (JSON or plaintext)"
  type        = string
}

variable "secret_access_policy_json" {
  description = "JSON policy for restricting access to the secret"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}
