resource "aws_lb" "app" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
  idle_timeout       = 60
  access_logs {
    bucket  = var.alb_logs_bucket
    enabled = true
  }

  tags = {
    Name        = var.alb_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "app" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
