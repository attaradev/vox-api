variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Controls whether image tags can be overwritten"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE"
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository (AES256 or KMS)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS"
  }
}

variable "encryption_kms_key" {
  description = "KMS key ARN when encryption_type is KMS"
  type        = string
  default     = ""
}

variable "lifecycle_policy" {
  description = "Optional JSON lifecycle policy document"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to the repository"
  type        = map(string)
  default     = {}
}
