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

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ecs_ssm_read" {
  name        = "${local.name_prefix}-ecs-ssm-read"
  description = "Allow ECS tasks to read specific SSM SecureString parameters (database URL, django secret)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "AllowGetParameter"
          Effect   = "Allow"
          Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
          Resource = local.ssm_parameters_for_ecs
        }
      ],
      var.ssm_parameter_kms_key_arn != "" ? [
        {
          Sid      = "AllowKmsDecrypt"
          Effect   = "Allow"
          Action   = ["kms:Decrypt"]
          Resource = [var.ssm_parameter_kms_key_arn]
        }
      ] : []
    )
  })

}

# The ecs_ssm_read policy will be merged into the main ecs_task_role_policy_map below

# Compute a canonical short environment name (prod/stg/dev/qa, etc.). Prefer a mapping
# from the long `var.environment` value; fall back to the explicit `var.short_environment`.
locals {
  short_environment = lookup(
    {
      production  = "prod"
      prod        = "prod"
      staging     = "stg"
      stage       = "stg"
      stg         = "stg"
      development = "dev"
      dev         = "dev"
      qa          = "qa"
    },
    lower(trimspace(var.environment)),
    var.short_environment
  )
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
  canonical_environment = lower(trimspace(var.environment))

  django_env = local.canonical_environment == "production" || local.canonical_environment == "prod" ? "production" : (local.canonical_environment == "staging" || local.canonical_environment == "stage" || local.canonical_environment == "stg" ? "staging" : "development")

  allowed_hosts_list = length(var.django_allowed_hosts) > 0 ? var.django_allowed_hosts : []
  allowed_hosts_csv  = length(local.allowed_hosts_list) > 0 ? join(",", local.allowed_hosts_list) : ""

  ecs_environment_base = merge(
    {
      DJANGO_ENV              = local.django_env
      FRONTEND_URL            = var.frontend_url
      AWS_STORAGE_BUCKET_NAME = module.storage.static_bucket_name
      STATIC_BUCKET_NAME      = module.storage.static_bucket_name
      MEDIA_BUCKET_NAME       = module.storage.media_bucket_name
      AWS_S3_REGION_NAME      = var.aws_region
      POSTGRES_DB             = module.storage.rds_dbname
      POSTGRES_USER           = module.storage.rds_username
      POSTGRES_HOST           = module.storage.rds_endpoint
      POSTGRES_PORT           = tostring(module.storage.rds_port)
      REDIS_HOST              = module.storage.redis_primary_endpoint
      REDIS_PORT              = "6379"
      USE_REDIS_FOR_CELERY    = "1"
    },
    length(local.allowed_hosts_csv) > 0 ? { DJANGO_ALLOWED_HOSTS = local.allowed_hosts_csv } : {},
    var.ecs_task_environment
  )

  ecs_environment = { for k, v in local.ecs_environment_base : k => tostring(v) if trimspace(k) != "" }

  ecs_environment_secrets = merge(
    {
      DATABASE_URL          = module.storage.database_url_ssm_name
      POSTGRES_PASSWORD     = module.storage.postgres_password_ssm_name
      SECRET_KEY            = module.storage.django_secret_key_ssm_name
      REDIS_PASSWORD        = module.storage.redis_auth_token_ssm_name
      REDIS_URL             = module.storage.redis_url_ssm_name
      CELERY_BROKER_URL     = module.storage.celery_broker_url_ssm_name
      CELERY_RESULT_BACKEND = module.storage.celery_result_backend_ssm_name
    },
    module.storage.stripe_webhook_secret_ssm_name != null ? { STRIPE_WEBHOOK_SECRET = module.storage.stripe_webhook_secret_ssm_name } : {},
    module.storage.stripe_secret_key_ssm_name != null ? { STRIPE_SECRET_KEY = module.storage.stripe_secret_key_ssm_name } : {},
    var.ecs_task_secrets
  )

  application_environment_plain   = local.ecs_environment
  application_environment_secrets = local.ecs_environment_secrets

  ssm_db_parameter_arn                = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.database_url_ssm_name}"
  ssm_django_parameter_arn            = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.django_secret_key_ssm_name}"
  ssm_postgres_password_parameter_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.postgres_password_ssm_name}"
  ssm_redis_auth_parameter_arn        = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.redis_auth_token_ssm_name}"
  ssm_redis_url_parameter_arn         = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.redis_url_ssm_name}"
  ssm_celery_broker_parameter_arn     = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.celery_broker_url_ssm_name}"
  ssm_celery_backend_parameter_arn    = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.celery_result_backend_ssm_name}"
  ssm_stripe_webhook_parameter_arn    = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.stripe_webhook_secret_ssm_name}"
  ssm_stripe_secret_parameter_arn     = module.storage.stripe_secret_key_ssm_name != null ? "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${module.storage.stripe_secret_key_ssm_name}" : null

  ssm_parameters_for_ecs = compact([
    local.ssm_db_parameter_arn,
    local.ssm_django_parameter_arn,
    local.ssm_postgres_password_parameter_arn,
    local.ssm_redis_auth_parameter_arn,
    local.ssm_redis_url_parameter_arn,
    local.ssm_celery_broker_parameter_arn,
    local.ssm_celery_backend_parameter_arn,
    local.ssm_stripe_webhook_parameter_arn,
    local.ssm_stripe_secret_parameter_arn
  ])

  name_prefix = lower(replace("${var.project}-${local.short_environment}", "_", "-"))
  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )

  ecs_additional_task_policies = {
    for idx, arn in var.ecs_task_role_policy_arns : format("extra_%02d", idx) => arn
    if trimspace(arn) != ""
  }

  ecs_task_role_policy_map = merge(
    { ssm_read_policy = aws_iam_policy.ecs_ssm_read.arn },
    local.ecs_additional_task_policies
  )
}

# ------------------------------------------------------------------------
# NETWORKING
# ------------------------------------------------------------------------

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

################################################################################
# INFRASTRUCTURE PROVISIONING ORDER: NETWORKING -> STORAGE -> ECS SERVICES
################################################################################

# -----------------------------------------------------------------------------
# 1. NETWORKING (VPC, Subnets, Routing, Security Groups, Load Balancer)
# -----------------------------------------------------------------------------
module "network" {
  source                    = "./modules/networking"
  name_prefix               = local.name_prefix
  cidr_block                = var.vpc_cidr_block
  availability_zones        = local.azs
  public_subnet_cidrs       = local.public_subnets
  private_app_subnet_cidrs  = local.private_app_subnets
  private_data_subnet_cidrs = local.computed_private_data_subnets
  single_nat_gateway        = var.single_nat_gateway
  flow_logs_log_group_name  = var.flow_logs_log_group_name
  adopt_existing_flow_logs  = var.adopt_existing_flow_logs
  tags                      = local.tags
  container_port            = var.container_port
}

# -----------------------------------------------------------------------------
# 2. STORAGE (S3, RDS, Redis, IAM Roles/Policies)
# -----------------------------------------------------------------------------

resource "random_password" "db" {
  length           = 24
  override_special = "!@#%&*()_+-=[]{}<>?"
}

resource "random_password" "redis" {
  length           = 32
  override_special = "!#$%&*()-_=+[]{}:;.,?<>"
  special          = true
}

module "storage" {
  source = "./modules/storage"

  name_prefix                  = local.name_prefix
  db_engine_version            = var.db_engine_version
  project                      = var.project
  tags                         = local.tags
  force_destroy                = var.s3_force_destroy
  versioning_enabled           = var.s3_versioning_enabled
  create_alb_log_bucket        = var.create_alb_log_bucket
  alb_log_force_destroy        = var.alb_log_force_destroy
  alb_log_kms_key_arn          = var.alb_log_kms_key_arn
  db_skip_final_snapshot       = var.db_skip_final_snapshot
  db_final_snapshot_identifier = var.db_final_snapshot_identifier

  db_security_group_id    = module.network.rds_security_group_id
  redis_security_group_id = module.network.redis_security_group_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = random_password.db.result

  db_subnet_group_name    = module.network.db_subnet_group_name
  redis_subnet_group_name = module.network.redis_subnet_group_name

  redis_auth_token          = random_password.redis.result
  bucket_suffix_override    = var.bucket_suffix_override
  bucket_suffix_length      = var.bucket_suffix_length
  stripe_secret_key         = var.stripe_secret_key
  ssm_parameter_kms_key_arn = var.ssm_parameter_kms_key_arn
}

# -----------------------------------------------------------------------------
# 3. ECS SERVICES (App Config, Cluster, Task Definitions, Services)
# -----------------------------------------------------------------------------
module "ecs" {
  source      = "./modules/ecs"
  name_prefix = local.name_prefix
  family      = "${local.name_prefix}-api"
  cpu         = var.ecs_cpu
  memory      = var.ecs_memory
  # execution_role_arn left blank to use module's created execution role or an explicit override
  container_image     = trimspace(var.container_image) != "" ? var.container_image : "${module.storage.ecr_repository_url}:latest"
  environment         = local.ecs_environment
  environment_secrets = local.ecs_environment_secrets
  # Image tag and ECR repo allow CI to drive new task definition revisions by calling
  # terraform apply -var 'image_tag=<shortsha>'
  ecr_repository_name       = module.storage.ecr_repository_name
  image_tag                 = var.image_tag
  aws_region                = var.aws_region
  enable_https_listener     = var.enable_https_listener
  ecs_log_group_name        = "${local.name_prefix}-ecs-logs"
  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_app_subnet_ids
  public_subnet_ids         = module.network.public_subnet_ids
  alb_security_group_id     = module.network.alb_security_group_id
  service_security_group_id = module.network.ecs_security_group_id
  container_port            = var.container_port
  desired_count             = var.ecs_desired_count
  log_retention_in_days     = var.ecs_log_retention_in_days
  certificate_arn           = var.certificate_arn
  ecs_cpu_high_alarm_name   = "${local.name_prefix}-ecs-cpu-high"
  ecs_unhealthy_alarm_name  = "${local.name_prefix}-ecs-unhealthy"
  depends_on                = [module.storage]
  tags                      = local.tags
  task_role_policy_arns     = local.ecs_task_role_policy_map
  celery_desired_count      = var.celery_desired_count
  celery_cpu                = var.celery_cpu
  celery_memory             = var.celery_memory
  celery_command            = var.celery_command
}
