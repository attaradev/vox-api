locals {
  name_prefix = lower(replace("${var.project}-${var.environment}", "_", "-"))
  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )
}
