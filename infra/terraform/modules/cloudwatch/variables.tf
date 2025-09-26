variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "kms_key_id" {
  description = "KMS Key ID for encrypting CloudWatch logs"
  type        = string
  default     = ""
}
