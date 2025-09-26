output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = aws_s3_bucket.media.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.media.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.media.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.media.arn
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table" {
  description = "DynamoDB table for Terraform state locking."
  value       = aws_dynamodb_table.terraform_lock.id
}
