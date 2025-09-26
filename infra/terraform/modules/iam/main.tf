resource "aws_iam_user_policy" "ses_smtp" {
  count = var.create_ses_smtp_credentials ? 1 : 0
  name  = var.ses_smtp_policy_name
  user  = var.ses_smtp_user_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = var.ses_identity_arn != "" ? [var.ses_identity_arn] : ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "app_bucket_access" {
  name        = var.app_bucket_access_name
  description = "Allow ECS task to access application buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.app_bucket_access_listbucket_arns
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = var.app_bucket_access_object_arns
      }
    ]
  })
}

resource "aws_iam_policy" "ses_send_email" {
  name        = var.ses_send_email_name
  description = "Allow ECS task to send emails via SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = var.ses_identity_arn != "" ? [var.ses_identity_arn] : ["*"]
      }
    ]
  })
}
