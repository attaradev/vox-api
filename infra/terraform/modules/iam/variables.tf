variable "create_ses_smtp_credentials" {
  description = "Whether to create SES SMTP credentials"
  type        = bool
}

variable "ses_smtp_policy_name" {
  description = "Name for the SES SMTP IAM user policy"
  type        = string
}

variable "ses_smtp_user_name" {
  description = "Name of the SES SMTP IAM user"
  type        = string
}

variable "app_bucket_access_name" {
  description = "Name for the S3 access policy"
  type        = string
}

variable "app_bucket_access_listbucket_arns" {
  description = "ListBucket ARNs for S3 access policy"
  type        = list(string)
}

variable "app_bucket_access_object_arns" {
  description = "Object ARNs for S3 access policy"
  type        = list(string)
}

variable "ses_send_email_name" {
  description = "Name for the SES send email policy"
  type        = string
}

variable "ses_identity_arn" {
  description = "Optional SES identity ARN (domain or email) to scope SES permissions"
  type        = string
  default     = ""
}
