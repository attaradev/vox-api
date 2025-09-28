locals {
  # short suffix to avoid global name collisions for S3 buckets
  # deterministic suffix derived from name_prefix so it's stable per environment/account
  computed_suffix = substr(md5(var.name_prefix), 0, var.bucket_suffix_length)
  bucket_suffix   = var.bucket_suffix_override != "" ? var.bucket_suffix_override : local.computed_suffix

  static_bucket_name  = lower(replace("${var.name_prefix}-static-${local.bucket_suffix}", "_", "-"))
  media_bucket_name   = lower(replace("${var.name_prefix}-media-${local.bucket_suffix}", "_", "-"))
  alb_logs_bucketname = lower(replace("${var.name_prefix}-alb-logs-${local.bucket_suffix}", "_", "-"))

  lifecycle_policy = trimspace(var.ecr_lifecycle_policy_json) != "" ? var.ecr_lifecycle_policy_json : jsonencode({
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

  repository_name = trimspace(var.ecr_repository_name) != "" ? var.ecr_repository_name : lower(replace(var.project, "_", "-"))
}

resource "aws_s3_bucket" "static" {
  bucket        = local.static_bucket_name
  force_destroy = var.force_destroy
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-static"
    Purpose = "static-files"
  })
}

resource "aws_s3_bucket" "media" {
  bucket        = local.media_bucket_name
  force_destroy = var.force_destroy
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-media"
    Purpose = "user-uploads"
  })
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "static" {
  bucket = aws_s3_bucket.static.id
  rule {
    id     = "expire-old-versions"
    status = var.versioning_enabled ? "Enabled" : "Disabled"
    filter {
      prefix = ""
    }
    noncurrent_version_expiration {
      noncurrent_days = 120
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    id     = "expire-old-versions"
    status = var.versioning_enabled ? "Enabled" : "Disabled"
    filter {
      prefix = ""
    }
    noncurrent_version_expiration {
      noncurrent_days = 120
    }
  }
}

resource "aws_s3_bucket" "alb_logs" {
  count         = var.create_alb_log_bucket ? 1 : 0
  bucket        = local.alb_logs_bucketname
  force_destroy = var.alb_log_force_destroy
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-alb-logs"
    Purpose = "alb-access-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count                   = var.create_alb_log_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.alb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  count  = var.create_alb_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.alb_log_kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.alb_log_kms_key_arn != "" ? var.alb_log_kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  count  = var.create_alb_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_ecr_repository" "app" {
  name                 = local.repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }
  encryption_configuration {
    encryption_type = var.ecr_encryption_type
    kms_key         = var.ecr_encryption_type == "KMS" ? var.ecr_encryption_kms_key : null
  }
  tags = var.tags
  lifecycle {
    precondition {
      condition     = var.ecr_encryption_type != "KMS" || length(trimspace(var.ecr_encryption_kms_key)) > 0
      error_message = "Provide ecr_encryption_kms_key when ecr_encryption_type is KMS"
    }
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy     = local.lifecycle_policy
}

# ------------------------------------------------------------------------
# SSM PARAMETERS & SECRETS
# ------------------------------------------------------------------------

resource "aws_ssm_parameter" "database_url" {
  name      = "/${var.name_prefix}/database_url"
  type      = "SecureString"
  value     = "postgresql://${aws_db_instance.postgres.username}:${aws_db_instance.postgres.password}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
  overwrite = true
  tags      = var.tags
}

resource "random_password" "django_secret_key" {
  length           = 50
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}"
}

# Store the Django secret in SSM Parameter Store as a SecureString so it can be referenced
# by ECS using containerDefinitions[].secrets valueFrom (ARN).
resource "aws_ssm_parameter" "django_secret_key" {
  name      = "/${var.name_prefix}/django_secret_key"
  type      = "SecureString"
  value     = random_password.django_secret_key.result
  overwrite = true
  tags      = var.tags
  key_id    = var.ssm_parameter_kms_key_arn != "" ? var.ssm_parameter_kms_key_arn : null
}

resource "random_password" "stripe_webhook_secret" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}"
}

# ------------------------------------------------------------------------
# RDS (Postgres)
# ------------------------------------------------------------------------
resource "aws_db_instance" "postgres" {
  allocated_storage = var.db_allocated_storage
  engine            = "postgres"
  engine_version    = var.db_engine_version != "" ? var.db_engine_version : null
  instance_class    = var.db_instance_class
  # Use the provided db_name or derive one from the name_prefix to follow the project's naming pattern.
  db_name  = var.db_name != "" ? var.db_name : lower(replace(var.name_prefix, "_", "-"))
  username = var.db_username
  password = var.db_password
  # Use the parameter group only when explicitly provided. Leaving this null lets AWS use
  # the default parameter group for the engine/version in the region.
  parameter_group_name      = var.db_parameter_group_name != "" ? var.db_parameter_group_name : null
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : (trim(var.db_final_snapshot_identifier) != "" ? var.db_final_snapshot_identifier : "${var.name_prefix}-final-snapshot")
  publicly_accessible       = var.db_publicly_accessible
  # Use networking module output for RDS security group
  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = var.db_subnet_group_name
  # RDS instance identifier follows the name_prefix by default to ensure predictable names.
  identifier = var.db_instance_identifier != "" ? var.db_instance_identifier : lower(replace(var.name_prefix, "_", "-"))
  tags       = var.tags
}

# ------------------------------------------------------------------------
# Redis (Elasticache)
# ------------------------------------------------------------------------
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "Redis replication group"
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_cache_clusters
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  engine                     = "redis"
  engine_version             = var.redis_engine_version
  port                       = 6379
  # Use networking module output for Redis security group
  security_group_ids         = [var.redis_security_group_id]
  subnet_group_name          = var.redis_subnet_group_name
  tags                       = var.tags
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = var.redis_auth_token
}
