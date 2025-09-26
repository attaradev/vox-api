variable "name_prefix" {
  description = "Prefix used for S3 buckets"
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow Terraform to delete non-empty buckets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to bucket resources"
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}
