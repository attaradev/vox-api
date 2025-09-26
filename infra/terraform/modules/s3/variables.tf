variable "s3_bucket_name" {
  description = "S3 bucket name for media/static files"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}
