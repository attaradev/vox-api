

locals {
  container_name         = "${var.name_prefix}-api"
  base_environment_map   = var.environment
  environment            = [for k, v in local.base_environment_map : { name = k, value = v }]
  celery_environment_map = merge(local.base_environment_map, var.celery_environment_overrides)
  celery_environment     = [for k, v in local.celery_environment_map : { name = k, value = v }]
  # Build secrets array for ECS task definition from map of env name => ssm param/arn
  secrets = [for k, v in var.environment_secrets :
    {
      name      = k
      valueFrom = (can(regex("^arn:aws:ssm:[^:]+:[0-9]+:parameter/.+", v)) ? v : "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${replace(v, "^/", "")}")
    }
  ]
  container_image_input = trimspace(var.container_image)
  container_image_parts = length(local.container_image_input) > 0 ? split(":", local.container_image_input) : []
  container_image_base  = length(local.container_image_parts) > 1 ? join(":", slice(local.container_image_parts, 0, length(local.container_image_parts) - 1)) : local.container_image_input
  image_tag_trimmed     = trimspace(var.image_tag)
  fallback_repo_name    = length(trimspace(var.ecr_repository_name)) > 0 ? trimspace(var.ecr_repository_name) : var.name_prefix
  image_repo_for_tag    = length(trimspace(local.container_image_base)) > 0 ? trimspace(local.container_image_base) : trimspace(local.fallback_repo_name)
  image_repo_effective  = length(local.image_repo_for_tag) > 0 ? local.image_repo_for_tag : local.fallback_repo_name
  container_image_effective = (
    length(local.image_tag_trimmed) > 0
    ? format("%s:%s", local.image_repo_effective, local.image_tag_trimmed)
    : local.container_image_input
  )
  container_health_command = length(var.container_health_command) > 0 ? var.container_health_command : [
    "CMD-SHELL",
    format("curl -f http://localhost:%d%s || exit 1", var.container_port, var.health_check_path)
  ]
  target_group_prefix_raw   = trimspace(substr(replace(var.name_prefix, "-", ""), 0, 5))
  target_group_prefix       = length(local.target_group_prefix_raw) > 0 ? local.target_group_prefix_raw : "tg"
  https_enabled             = var.enable_https_listener && length(trimspace(var.certificate_arn)) > 0
  effective_certificate_arn = local.https_enabled ? trimspace(var.certificate_arn) : ""
}

data "aws_elb_service_account" "this" {}

data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster"
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${var.name_prefix}-service"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-logs"
  })
}

resource "aws_iam_role" "execution" {
  name = "${var.name_prefix}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_ssm" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role" "task" {
  name = "${var.name_prefix}-ecs-task"

  assume_role_policy = aws_iam_role.execution.assume_role_policy

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_additional" {
  for_each   = var.task_role_policy_arns
  role       = aws_iam_role.task.name
  policy_arn = each.value
}

resource "random_id" "alb_logs" {
  byte_length = 4
}

resource "aws_s3_bucket" "access_logs" {
  bucket = lower(replace("${var.name_prefix}-alb-logs-${random_id.alb_logs.hex}", "_", "-"))

  force_destroy = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.this.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.access_logs.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.this.arn
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.access_logs.arn
      }
    ]
  })
}

resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    enabled = true
    prefix  = "alb"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "this" {
  name_prefix = "${local.target_group_prefix}-"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200-399"
    path                = var.health_check_path
  }

  deregistration_delay = 30

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-tg"
  })
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.https_enabled ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = local.https_enabled ? [] : [1]
      content {
        target_group {
          arn = aws_lb_target_group.this.arn
        }
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.effective_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = local.container_image_effective
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = local.celery_environment
      secrets     = local.secrets
      healthCheck = {
        command     = local.container_health_command
        interval    = var.container_health_interval
        timeout     = var.container_health_timeout
        retries     = var.container_health_retries
        startPeriod = var.container_health_start_period
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-task"
  })
}

resource "aws_ecs_service" "this" {
  name             = "${var.name_prefix}-service"
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  health_check_grace_period_seconds = var.ecs_health_check_grace_period_seconds

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-service"
  })
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.scale_max_capacity
  min_capacity       = var.scale_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name_prefix}-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.scale_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.name_prefix}-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.scale_memory_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

resource "aws_cloudwatch_log_group" "celery" {
  count             = var.celery_desired_count > 0 ? 1 : 0
  name              = "/aws/ecs/${var.name_prefix}-celery"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-celery-logs"
  })
}

resource "aws_ecs_task_definition" "celery" {
  count                    = var.celery_desired_count > 0 ? 1 : 0
  family                   = "${var.name_prefix}-celery"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.celery_cpu)
  memory                   = tostring(var.celery_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "${var.name_prefix}-celery"
      image     = local.container_image_effective
      essential = true
      command   = var.celery_command
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.celery[count.index].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "celery"
        }
      }
      environment = local.environment
      secrets     = local.secrets
      healthCheck = {
        command     = ["CMD-SHELL", "celery -A vox_api inspect ping --timeout=10 || exit 1"]
        interval    = 60
        timeout     = 10
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-celery-task"
  })
}

resource "aws_ecs_service" "celery" {
  count            = var.celery_desired_count > 0 ? 1 : 0
  name             = "${var.name_prefix}-celery"
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.celery[count.index].arn
  desired_count    = var.celery_desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-celery"
  })
}

data "aws_region" "current" {}
