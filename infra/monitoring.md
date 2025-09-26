# Monitoring plan for vox-api

## Purpose

This document describes a pragmatic, staged monitoring plan for the vox-api project and the AWS infrastructure it runs on (ECS Fargate, ALB, RDS, ElastiCache Redis, S3, SSM).

## Goals

- Capture application logs and container metrics.
- Alert on critical availability and performance issues.
- Provide error-tracing and a path to build dashboards and runbooks.

### Staged approach

1) Minimal (quick win)
   - CloudWatch Log Groups for app & celery (14 day retention).
   - Ensure ECS task `logConfiguration` uses `awslogs` and streams logs to those groups.
   - Enable CloudWatch Container Insights for the cluster.
   - Create SNS topic `monitoring-alerts` and sample CloudWatch alarms:
     - ALB 5xx spike
     - ECS desired vs running tasks mismatch
     - RDS high CPU and low free storage
     - Redis evictions
   - Subscribe an ops email to the SNS topic for alerts.

2) Observability (next)
   - Add OpenTelemetry / ADOT collector sidecar or an X-Ray daemon, instrument Django/Celery.
   - Expose Prometheus `/metrics` on Django; add celery metrics exporter.
   - Store metrics in CloudWatch metrics or push to Prometheus/Grafana (hosted or self-hosted).

3) Error tracking & SLOs
   - Integrate Sentry for exceptions (DSN stored in SSM SecureString).
   - Build dashboards for P95/P99 latencies, error rates, DB connections, Redis memory/evictions.
   - Define SLOs and alerts mapped to runbooks and PagerDuty.

Terraform work (minimal to start)

- CloudWatch log groups
  - `aws_cloudwatch_log_group.app`
  - `aws_cloudwatch_log_group.celery`
  - Configurable `retention_in_days` variable (14 default)

- Container Insights
  - Enable `aws_ecs_cluster_setting` with `containerInsights = enabled` or document how to enable via console if insufficient permissions.

- SNS & alarms
  - `aws_sns_topic.monitoring_alerts`
  - `aws_cloudwatch_metric_alarm.alb_5xx`
  - `aws_cloudwatch_metric_alarm.ecs_task_count_mismatch`
  - `aws_cloudwatch_metric_alarm.rds_high_cpu`
  - `aws_cloudwatch_metric_alarm.redis_evictions`

- CloudWatch Dashboard (optional)
  - `aws_cloudwatch_dashboard.monitoring` with widgets for ALB, ECS, RDS, Redis and application errors

### App changes (recommended)

- Logging
  - Switch to structured JSON logs (python `logging` with JSON formatter or `structlog`).
  - Forward logs via awslogs or FireLens (Fluent Bit) for richer routing.

- Errors
  - Add Sentry (recommended) with DSN in SSM. Initialize in Django settings and Celery.

- Metrics
  - Add `prometheus_client` and expose `/metrics` endpoint behind auth or at an internal path.
  - Add Celery exporter.

Tracing

- Short path: instrument app with OpenTelemetry and use the ADOT collector sidecar to forward to X-Ray.
- Longer path: ADOT -> Grafana Tempo / Jaeger / Honeycomb.

Alert thresholds (starter values)

- ALB 5xx count > 5 in 5 minutes OR 5xx rate > 1% (tune for traffic)
- ECS desired_count != running_count for > 2 minutes
- RDS CPUUtilization > 80% for 5 minutes
- RDS FreeStorageSpace < 10 GB
- Redis EvictedKeys > 0 in 5 minutes

Runbook templates (examples)

- ALB 5xx spike
  1. Open the ALB target group metrics and check which targets are returning 5xx.
  2. Inspect the latest logs in CloudWatch for the `app` and `celery` groups for stack traces.
  3. Check recent ECS deployments in the service to rule out bad image/config.
  4. If retries or increased latency, consider rolling back the last deploy.

- ECS tasks failing to reach healthy
  1. Check service events for failing health checks.
  2. Inspect task log stream under the app log group for the failing task's container.
  3. If native healthcheck fails, run locally to reproduce and check dependencies (DB, cache).

- RDS low storage
  1. Check recent backup/restore activity and retention.
  2. Consider increasing allocated storage or purging large tables/indexes.

Next steps & decision points

- Confirm whether you want the minimal Terraform baseline implemented (log groups, Container Insights, SNS + a set of alarms) — I can implement and validate with `terraform validate` and a staged apply in non-prod.
- Decide whether to add Sentry now (requires a DSN / project) or later.

Contact & notes

- Costs: logs and Container Insights incur CloudWatch charges; keep retention conservative initially.
- IAM: ECS task role will need permissions for X-Ray or ADOT if you enable tracing; alarms/SNS managed by Terraform will create IAM resources as necessary.
