output "static_bucket_name" {
  value       = aws_s3_bucket.static.bucket
  description = "Name of the S3 bucket for static assets"
}

output "media_bucket_name" {
  value       = aws_s3_bucket.media.bucket
  description = "Name of the S3 bucket for media uploads"
}
