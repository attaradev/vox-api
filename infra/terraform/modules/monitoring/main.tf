
resource "aws_cloudwatch_log_group" "celery" {
  name              = var.celery_log_group_name
  retention_in_days = var.celery_log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "ecs_service" {
  name              = var.ecs_service_log_group_name
  retention_in_days = var.ecs_service_log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.ecs_service_name}-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = var.namespace
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_cpu_alarm_threshold
  alarm_description   = "ECS service CPU utilization is high"
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
  treat_missing_data = "missing"
  tags               = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_unhealthy" {
  alarm_name          = "${var.ecs_service_name}-unhealthy-tasks"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyTaskCount"
  namespace           = var.namespace
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "ECS service has unhealthy tasks"
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
  treat_missing_data = "missing"
  tags               = var.tags
}
