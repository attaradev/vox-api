terraform {
  backend "s3" {
    bucket       = "vox-api-terraform-state"
    key          = "state/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = var.skip_aws_account_checks
  skip_metadata_api_check     = var.skip_aws_account_checks
  skip_region_validation      = var.skip_aws_account_checks
  skip_requesting_account_id  = var.skip_aws_account_checks
}

locals {
  environment = var.environment
  common_tags = merge({
    Environment = local.environment
    ManagedBy   = "Terraform"
  }, var.additional_tags)
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "random_password" "app_secret_key" {
  length  = 32
  special = true
}

resource "random_password" "app_api_token" {
  length  = 32
  special = true
}

module "vpc" {
  source          = "./modules/vpc"
  vpc_name        = var.vpc_name
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  tags            = merge(local.common_tags, { Name = var.vpc_name })
}

module "cloudwatch" {
  source         = "./modules/cloudwatch"
  log_group_name = var.cloudwatch_log_group_name
  kms_key_id     = var.cloudwatch_kms_key_id
  tags           = local.common_tags
}

module "s3_media" {
  source         = "./modules/s3"
  s3_bucket_name = var.s3_bucket_name
  tags           = merge(local.common_tags, { Purpose = "app-media" })
}

module "s3_logs" {
  source         = "./modules/s3"
  s3_bucket_name = var.alb_logs_bucket
  allow_log_delivery = true
  tags               = merge(local.common_tags, { Purpose = "alb-access-logs" })
}

resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-sg"
  description = "Security group for the Vox API ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.alb_name}-sg"
  })
}

resource "aws_security_group" "ecs_tasks" {
  name        = var.asg_sg_name
  description = "Security group for Vox API ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic from the ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = var.asg_sg_name
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.rds_identifier}-sg"
  description = "Security group for Vox API RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.rds_identifier}-sg"
  })
}

resource "aws_security_group" "redis" {
  name        = "${var.elasticache_cluster_id}-sg"
  description = "Security group for Vox API ElastiCache"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.elasticache_cluster_id}-sg"
  })
}

resource "aws_security_group" "endpoints" {
  name        = "vox-api-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow HTTPS from ECS tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "vox-api-endpoints-sg"
  })
}

module "alb" {
  source             = "./modules/alb"
  alb_name           = var.alb_name
  security_group_ids = [aws_security_group.alb.id]
  subnet_ids         = module.vpc.public_subnets
  target_group_name  = var.alb_target_group_name
  vpc_id             = module.vpc.vpc_id
  alb_logs_bucket    = module.s3_logs.s3_bucket_name
  tags               = local.common_tags
}

module "ecs" {
  source                             = "./modules/ecs"
  ecs_cluster_name                   = var.ecs_cluster_name
  default_capacity_provider_strategy = var.default_capacity_provider_strategy
  tags                               = merge(local.common_tags, { Name = var.ecs_cluster_name })
}

module "elasticache" {
  source             = "./modules/elasticache"
  cluster_id         = var.elasticache_cluster_id
  node_type          = var.elasticache_node_type
  num_cache_nodes    = var.elasticache_num_cache_nodes
  subnet_group_name  = var.elasticache_subnet_group_name
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.redis.id]
  tags               = local.common_tags
}

module "rds" {
  source                 = "./modules/rds"
  rds_identifier         = var.rds_identifier
  rds_instance_class     = var.rds_instance_class
  db_username            = var.db_username
  db_password            = random_password.db_password.result
  db_name                = var.db_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.vpc.private_subnets
  family                 = var.db_family
  multi_az               = var.rds_multi_az
  tags                   = merge(local.common_tags, { Name = var.rds_identifier })
}

module "iam" {
  source             = "./modules/iam"
  role_name          = var.iam_role_name
  inline_policy_json = var.iam_inline_policy_json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  for_each   = toset(var.ecs_task_execution_policy_arns)
  role       = module.iam.role_name
  policy_arn = each.value
}

module "asm_rds" {
  source      = "./modules/asm"
  secret_name = var.asm_secret_name
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    db_name  = var.db_name
  })
  secret_access_policy_json = var.asm_secret_access_policy_json
  tags                      = local.common_tags
}

module "asm_app" {
  source      = "./modules/asm"
  secret_name = "vox-api-app-secret"
  secret_string = jsonencode({
    app_key   = random_password.app_secret_key.result
    api_token = random_password.app_api_token.result
  })
  secret_access_policy_json = var.asm_secret_access_policy_json
  tags                      = local.common_tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
  tags              = merge(local.common_tags, { Name = "vox-api-s3-endpoint" })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.endpoints.id]
  tags               = merge(local.common_tags, { Name = "vox-api-secretsmanager-endpoint" })
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.endpoints.id]
  tags               = merge(local.common_tags, { Name = "vox-api-cloudwatch-endpoint" })
}

resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
  tags = merge(local.common_tags, {
    Name = var.ecr_repository_name
  })
}

resource "aws_ssm_parameter" "database_url" {
  name      = "/vox-api/database-url"
  type      = "SecureString"
  value     = "postgres://${var.db_username}:${random_password.db_password.result}@${module.rds.rds_endpoint}:${module.rds.rds_port}/${var.db_name}"
  overwrite = true
  tags = merge(local.common_tags, {
    Name = "vox-api-database-url"
  })
}

resource "aws_secretsmanager_secret" "django_secret_key" {
  name        = "vox-api-django-secret-key"
  description = "Django secret key for Vox API"
  tags = merge(local.common_tags, {
    Name = "vox-api-django-secret-key"
  })
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = random_password.app_secret_key.result
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.ecs_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = module.iam.role_arn
  container_definitions = jsonencode([
    {
      name         = "app"
      image        = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
      essential    = true
      portMappings = [{ containerPort = 8000, protocol = "tcp" }]
      secrets = [
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.django_secret_key.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = aws_ssm_parameter.database_url.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.cloudwatch.log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = var.ecs_service_name
  cluster         = module.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "app"
    container_port   = 8000
  }
  depends_on = [module.alb]
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = merge(local.common_tags, {
    Name = var.ecs_service_name
  })
}
