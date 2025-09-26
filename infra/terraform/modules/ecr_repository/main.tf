locals {
  lifecycle_policy = trimspace(var.lifecycle_policy) != "" ? var.lifecycle_policy : jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain the most recent 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.encryption_kms_key : null
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.encryption_type != "KMS" || length(trimspace(var.encryption_kms_key)) > 0
      error_message = "encryption_kms_key must be supplied when encryption_type is set to KMS"
    }
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = local.lifecycle_policy
}
