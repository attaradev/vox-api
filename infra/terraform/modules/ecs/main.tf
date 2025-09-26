module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.0.0"

  cluster_name                       = var.ecs_cluster_name
  default_capacity_provider_strategy = var.default_capacity_provider_strategy != null ? var.default_capacity_provider_strategy : {}
  tags                               = var.tags
}
