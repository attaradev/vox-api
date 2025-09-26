resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.log_group_name
  retention_in_days = 14
  kms_key_id        = length(trimspace(var.kms_key_id)) > 0 ? var.kms_key_id : null
  tags = merge(var.tags, {
    Name = var.log_group_name
  })
}
