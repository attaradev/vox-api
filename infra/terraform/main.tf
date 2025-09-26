terraform {
  backend "s3" {
    bucket         = "vox-api-terraform-state"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "vox-api-terraform-lock"
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
  region = var.aws_region
}

module "elasticache" {
  source             = "./modules/elasticache"
  cluster_id         = "vox-api-redis-cluster"
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 1
  subnet_group_name  = "vox-api-redis-subnet-group"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.asg.security_group_id]
}
module "asg" {
  source  = "./modules/asg"
  sg_name = "vox-api-ecs-sg"
  vpc_id  = module.vpc.vpc_id
}
module "alb" {
  source             = "./modules/alb"
  alb_name           = "vox-api-alb"
  security_group_ids = [module.asg.security_group_id]
  subnet_ids         = module.vpc.public_subnets
  target_group_name  = "vox-api-alb-tg"
  vpc_id             = module.vpc.vpc_id
  alb_logs_bucket    = var.s3_bucket_name
}
module "cloudwatch" {
  source         = "./modules/cloudwatch"
  log_group_name = "vox-api-ecs-logs"
}
module "asm_rds" {
  source      = "./modules/asm"
  secret_name = var.asm_secret_name
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    db_name  = var.db_name
  })
  secret_access_policy_json = var.asm_secret_access_policy_json
}
module "asm_app" {
  source      = "./modules/asm"
  secret_name = "vox-api-app-secret"
  secret_string = jsonencode({
    app_key   = var.app_secret_key
    api_token = var.app_api_token
  })
  secret_access_policy_json = var.asm_secret_access_policy_json
}

module "vpc" {
  source          = "./modules/vpc"
  vpc_name        = "vox-api-vpc"
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

module "ecs" {
  source           = "./modules/ecs"
  ecs_cluster_name = "vox-api-ecs-cluster"
}

module "rds" {
  source                 = "./modules/rds"
  rds_identifier         = "vox-api-rds"
  rds_instance_class     = var.rds_instance_class
  db_username            = var.db_username
  db_password            = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = [module.asg.security_group_id]
  subnet_ids             = module.vpc.private_subnets
}

module "s3" {
  source         = "./modules/s3"
  s3_bucket_name = "vox-api-s3"
}

module "iam" {
  source    = "./modules/iam"
  role_name = "vox-api-ecs-task-execution-role"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.asg.security_group_id]
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.asg.security_group_id]
}

resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
  tags = {
    Name        = var.ecr_repository_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecs_cluster" "app" {
  name = var.ecs_cluster_name
  tags = {
    Name        = var.ecs_cluster_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_ssm_parameter" "database_url" {
  name  = "/vox-api/database-url"
  type  = "SecureString"
  value = var.database_url
}

resource "aws_secretsmanager_secret" "django_secret_key" {
  name        = "vox-api-django-secret-key"
  description = "Django secret key for Vox API"
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = var.app_secret_key
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
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.asg.security_group_id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "app"
    container_port   = 8000
  }
  depends_on = [module.alb]
  tags = {
    Name        = var.ecs_service_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
