module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.0.0"

  cluster_name = var.ecs_cluster_name
}
