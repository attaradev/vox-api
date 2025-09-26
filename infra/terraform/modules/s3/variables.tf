variable "s3_bucket_name" {
  description = "S3 bucket name for media/static files"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "allow_log_delivery" {
  description = "Allow AWS services such as ALB or CloudFront to deliver logs to the bucket"
  type        = bool
  default     = false
}
