terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project     = var.project
        Environment = var.environment
      },
      var.additional_tags
    )
  }
}

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

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  subnet_newbits = 4

  computed_public_subnets = [
    for idx in range(length(local.azs)) :
    cidrsubnet(var.vpc_cidr_block, local.subnet_newbits, idx)
  ]

  computed_private_app_subnets = [
    for idx in range(length(local.azs)) :
    cidrsubnet(var.vpc_cidr_block, local.subnet_newbits, idx + length(local.azs))
  ]

  computed_private_data_subnets = [
    for idx in range(length(local.azs)) :
    cidrsubnet(var.vpc_cidr_block, local.subnet_newbits, idx + length(local.azs) * 2)
  ]

  public_subnets       = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : local.computed_public_subnets
  private_app_subnets  = length(var.private_app_subnet_cidrs) > 0 ? var.private_app_subnet_cidrs : local.computed_private_app_subnets
  private_data_subnets = length(var.private_data_subnet_cidrs) > 0 ? var.private_data_subnet_cidrs : local.computed_private_data_subnets
}

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "aws_iam_role" "ecs_task_execution" {
  count = var.create_iam_role ? 0 : 1
  name  = "${local.name_prefix}-ecs-execution"
}

data "aws_secretsmanager_secret" "django_secret_key" {
  count = var.create_shared_resources ? 0 : 1
  name  = "${local.name_prefix}-django-settings"
}

data "aws_s3_bucket" "logs" {
  count  = var.create_shared_resources ? 0 : 1
  bucket = "${local.name_prefix}-logs"
}

data "aws_ecr_repository" "app" {
  count = var.create_shared_resources ? 0 : 1
  name  = "${local.name_prefix}-api"
}

data "aws_lb_target_group" "app" {
  count = var.create_alb ? 0 : 1
  name  = "${local.name_prefix}-api"
}

data "aws_cloudwatch_log_group" "ecs" {
  count = var.create_cloudwatch_log_groups ? 0 : 1
  name  = "/aws/ecs/${local.name_prefix}-service"
}

data "aws_cloudwatch_log_group" "celery" {
  count = var.create_cloudwatch_log_groups ? 0 : 1
  name  = "/aws/ecs/${local.name_prefix}-celery"
}

data "aws_s3_bucket" "static" {
  count  = var.create_shared_resources ? 0 : 1
  bucket = "${local.name_prefix}-static"
}

module "network" {
  source = "./modules/network"

  name                      = local.name_prefix
  cidr_block                = var.vpc_cidr_block
  availability_zones        = local.azs
  public_subnet_cidrs       = local.public_subnets
  private_app_subnet_cidrs  = local.private_app_subnets
  private_data_subnet_cidrs = local.private_data_subnets
  single_nat_gateway        = var.single_nat_gateway
  tags                      = local.tags
}

# -----------------------------------------------------------------------------
# SECURITY GROUPS
# -----------------------------------------------------------------------------

resource "random_id" "alb_sg_suffix" {
  byte_length = 16
  keepers = {
    vpc_id = module.network.vpc_id
  }
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-${random_id.alb_sg_suffix.hex}"
  description = "Allow inbound web traffic"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_allowed_cidrs
  }

  dynamic "ingress" {
    for_each = var.enable_https_listener ? [1] : []
    content {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.alb_allowed_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs"
  description = "Allow traffic from ALB and within the service"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "Allow from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Allow from self"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-ecs"
  })
}

# -----------------------------------------------------------------------------
# STORAGE
# -----------------------------------------------------------------------------

module "s3_buckets" {
  source = "./modules/s3_buckets"

  name_prefix   = local.name_prefix
  force_destroy = var.s3_force_destroy
  tags          = local.tags
}

module "ecr" {
  source = "./modules/ecr_repository"

  name                 = "${local.name_prefix}-api"
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  encryption_type      = var.ecr_encryption_type
  encryption_kms_key   = var.ecr_encryption_kms_key
  lifecycle_policy     = var.ecr_lifecycle_policy_json
  tags                 = local.tags
}

resource "aws_iam_policy" "app_bucket_access" {
  name        = "${local.name_prefix}-s3-access"
  description = "Allow ECS task to access application buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${module.s3_buckets.static_bucket_name}",
          "arn:aws:s3:::${module.s3_buckets.media_bucket_name}"
        ]
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
        Resource = [
          "arn:aws:s3:::${module.s3_buckets.static_bucket_name}/*",
          "arn:aws:s3:::${module.s3_buckets.media_bucket_name}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# DATA LAYER
# -----------------------------------------------------------------------------

locals {
  db_allowed_security_groups = concat([aws_security_group.ecs.id], var.db_additional_allowed_security_group_ids)
}

module "rds" {
  source = "./modules/rds"

  name_prefix                = local.name_prefix
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_data_subnet_ids
  allowed_security_group_ids = local.db_allowed_security_groups
  db_name                    = var.db_name
  username                   = var.db_username
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  max_allocated_storage      = var.db_max_allocated_storage
  backup_retention_period    = var.db_backup_retention_period
  multi_az                   = var.db_multi_az
  apply_immediately          = var.db_apply_immediately
  secret_name                = var.db_secret_name
  existing_master_password   = var.db_existing_password
  tags                       = local.tags
}

module "redis" {
  source = "./modules/redis"

  name_prefix                = local.name_prefix
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_data_subnet_ids
  allowed_security_group_ids = [aws_security_group.ecs.id]
  engine_version             = var.redis_engine_version
  node_type                  = var.redis_node_type
  replicas_per_node_group    = var.redis_replicas_per_node_group
  num_node_groups            = var.redis_num_node_groups
  maintenance_window         = var.redis_maintenance_window
  snapshot_window            = var.redis_snapshot_window
  snapshot_retention_limit   = var.redis_snapshot_retention_limit
  tags                       = local.tags
}

# -----------------------------------------------------------------------------
# PARAMETER STORE
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "database_url" {
  name      = "/${local.name_prefix}/database_url"
  type      = "SecureString"
  value     = module.rds.secret_arn
  overwrite = true

  tags = local.tags
}

# -----------------------------------------------------------------------------
# SECRETS
# -----------------------------------------------------------------------------

resource "random_password" "django_secret_key" {
  length           = 50
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "django" {
  name        = "${local.name_prefix}-django-settings"
  description = "Django application secrets for ${local.name_prefix}"

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-django-settings"
  })
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id = aws_secretsmanager_secret.django.id

  secret_string = jsonencode({
    DJANGO_SECRET_KEY = random_password.django_secret_key.result
  })
}

# -----------------------------------------------------------------------------
# COMPUTE
# -----------------------------------------------------------------------------

locals {
  ecs_task_role_policy_map = merge(
    {
      app_bucket_access = aws_iam_policy.app_bucket_access.arn
    },
    { for idx, arn in var.ecs_task_role_policy_arns : "extra_${idx}" => arn }
  )

  ecs_task_secret_defaults = {
    DATABASE_URL      = "${module.rds.secret_arn}:database_url::"
    REDIS_URL         = "${module.redis.secret_arn}:redis_url::"
    REDIS_READER_URL  = "${module.redis.secret_arn}:redis_reader_url::"
    DJANGO_SECRET_KEY = "${aws_secretsmanager_secret.django.arn}:DJANGO_SECRET_KEY::"
  }

  ecs_task_secret_overrides = { for secret in var.ecs_task_secrets : secret.name => secret.value_from }

  ecs_task_secret_bindings = [
    for name, value in merge(local.ecs_task_secret_defaults, local.ecs_task_secret_overrides) : {
      name       = name
      value_from = value
    }
  ]

  # Default environment variables for the Django application
  default_environment = {
    DJANGO_ENV              = "production"
    CELERY_BROKER_URL       = "redis://${module.redis.primary_endpoint}:${module.redis.port}/0"
    CELERY_RESULT_BACKEND   = "redis://${module.redis.primary_endpoint}:${module.redis.port}/0"
    FRONTEND_URL            = var.frontend_url
    AWS_STORAGE_BUCKET_NAME = var.create_shared_resources ? module.s3_buckets.static_bucket_name : data.aws_s3_bucket.static[0].bucket
  }

  ecs_environment = merge(local.default_environment, var.ecs_task_environment)
}

module "ecs_service" {
  source = "./modules/ecs_service"

  name_prefix               = local.name_prefix
  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_app_subnet_ids
  public_subnet_ids         = module.network.public_subnet_ids
  alb_security_group_id     = aws_security_group.alb.id
  service_security_group_id = aws_security_group.ecs.id
  container_image           = var.container_image != "" ? var.container_image : "${module.ecr.repository_url}:bootstrap"
  container_port            = var.container_port
  desired_count             = var.ecs_desired_count
  cpu                       = var.ecs_cpu
  memory                    = var.ecs_memory
  environment               = local.ecs_environment
  secrets                   = local.ecs_task_secret_bindings
  log_retention_in_days     = var.ecs_log_retention_in_days
  enable_https_listener     = var.enable_https_listener
  certificate_arn           = var.certificate_arn
  scale_min_capacity        = var.ecs_scale_min_capacity
  scale_max_capacity        = var.ecs_scale_max_capacity
  scale_cpu_target          = var.ecs_scale_cpu_target
  scale_memory_target       = var.ecs_scale_memory_target
  task_role_policy_arns     = local.ecs_task_role_policy_map
  tags                      = local.tags
}

# -----------------------------------------------------------------------------
# CELERY WORKERS
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "celery" {
  name              = "/aws/ecs/${local.name_prefix}-celery"
  retention_in_days = var.ecs_log_retention_in_days

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-celery-logs"
  })
}

resource "aws_ecs_task_definition" "celery" {
  family                   = "${local.name_prefix}-celery"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.celery_cpu
  memory                   = var.celery_memory
  execution_role_arn       = module.ecs_service.task_execution_role_arn
  container_definitions = jsonencode([
    {
      name      = "celery"
      image     = var.container_image != "" ? var.container_image : "${module.ecr.repository_url}:bootstrap"
      essential = true
      command   = ["celery", "-A", "vox_api", "worker", "--loglevel=info"]
      secrets = [
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret_version.django.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = aws_ssm_parameter.database_url.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${local.name_prefix}-celery"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "celery"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "celery" {
  name            = "${local.name_prefix}-celery"
  cluster         = module.ecs_service.cluster_name
  task_definition = aws_ecs_task_definition.celery.arn
  desired_count   = var.celery_desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = module.network.private_app_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_ssm_parameter.database_url
  ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-celery"
  })
}
