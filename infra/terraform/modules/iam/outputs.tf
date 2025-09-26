
output "app_bucket_access_policy_arn" {
  value       = aws_iam_policy.app_bucket_access.arn
  description = "ARN for S3 access policy"
}

output "ses_send_email_policy_arn" {
  value       = aws_iam_policy.ses_send_email.arn
  description = "ARN for SES send email policy"
}
