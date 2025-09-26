module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway               = true
  single_nat_gateway               = true
  enable_flow_log                  = true
  flow_log_cloudwatch_iam_role_arn = var.vpc_flow_log_role_arn
}
