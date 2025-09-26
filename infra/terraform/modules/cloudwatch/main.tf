resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.log_group_name
  retention_in_days = 14
  kms_key_id        = var.kms_key_id

  tags = {
    Name        = var.log_group_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
