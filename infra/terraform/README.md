# Vox API Terraform Infrastructure

This directory contains the production-ready Terraform configuration for deploying Vox API into AWS with a secure, highly-available baseline. The infrastructure is now fully modularized under `infra/terraform/modules/` for maintainability, reusability, and environment support.

Key improvements:

- VPC flow logs are optional and can be enabled/disabled via the `enable_vpc_flow_logs` variable.

- All AWS resources are managed via dedicated modules: networking, ecs, iam, load_balancer, storage, monitoring.
- Environment support via Terraform workspaces and consistent naming convention: `<project>-<env>-<resource>`.
- Outputs are exposed and wired between modules for seamless integration.
   All required resources are always created; there are no resource toggles or flags.

Key design goals include:

- All compute, databases, and caches run in private subnets; only the Application Load Balancer is public.
- Encryption everywhere: RDS, ElastiCache, and S3 buckets enforce encryption at rest and in transit.
- Operational resilience via multi-AZ networking, redundant NAT gateways, autoscaling ECS services, and managed backing services.
- Consolidated, maintainable Terraform code that cleanly separates concerns within a single file.

## Architecture Overview

Provisioned components include:

- **Networking:** Dedicated VPC with public, private application, and private data subnets across multiple AZs; internet gateway, NAT gateways, VPC flow logs, and private VPC endpoints for AWS APIs frequently used by the workload.
- **Compute:** AWS Fargate/ECS cluster with separate autoscaled services for the Django API (fronted by an Application Load Balancer) and Celery background workers. ALB access logs are retained in a locked-down S3 bucket.
- **Data:** Amazon RDS for PostgreSQL and ElastiCache for Redis (encryption enabled). Defaults favour development labs (`db.t3.micro`, `cache.t4g.micro`, single-AZ) and can be scaled up via variables. Credentials and auth tokens are generated automatically and surfaced through Terraform outputs for injection into workloads.
- **Storage:** Private S3 buckets for static assets and media uploads with versioning, lifecycle policies, and default encryption.
- **Email Service:** Amazon SES for transactional email with optional domain verification, DKIM signing, and SMTP credentials. ECS tasks are granted IAM permissions to send emails via SES API.
- **Container Registry:** Private Amazon ECR repository with scan-on-push, tag immutability, and lifecycle rules for pruning older images.
- **Runtime Config:** Terraform outputs expose a complete environment-variable map (`application_environment`) with database URLs, Redis endpoints, and application secrets so the deployment pipeline can inject configuration directly into ECS task definitions.

The resulting infrastructure isolates all stateful services in private subnets and exposes only the ALB to the public internet.

## Prerequisites

1. Terraform `>= 1.4` and the AWS CLI configured with credentials.
2. A remote state backend (recommended) matching the references in `backend.tf`:

   ```bash
   aws s3api create-bucket --bucket vox-api-terraform-state --region us-east-1 --create-bucket-configuration LocationConstraint=us-east-1
   aws s3api put-bucket-versioning --bucket vox-api-terraform-state --versioning-configuration Status=Enabled
   aws dynamodb create-table \
     --table-name vox-api-terraform-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

   Adjust bucket/table names or the backend configuration if you need different conventions.

3. CI/CD credentials capable of pushing the Vox API image into the provisioned ECR repository (see the `ecr_repository_url` output).

## Layout

```md
infra/terraform/
├── backend.tf             # Remote state (S3 + DynamoDB) configuration
├── main.tf                # Root module wiring all submodules and outputs
├── outputs.tf             # Key outputs for integration and secrets
├── variables.tf           # Root module inputs and toggles
├── terraform.tfvars.example
└── modules/
   ├── networking/        # VPC, subnets, security groups
   ├── ecs/               # ECS cluster, services, task definitions
   ├── iam/               # IAM roles, policies for least-privilege
   ├── alb/               # Application Load Balancer and target groups
   ├── storage/           # S3 buckets, SSM parameters, secrets
   └── monitoring/        # CloudWatch log groups, alarms
```

Each module exposes variables and outputs for composition. The root `main.tf` wires outputs between modules and provides environment-wide configuration.

## Getting Started

### VPC Flow Logs (Optional)

To enable or disable VPC flow logs, set the `enable_vpc_flow_logs` variable in your `terraform.tfvars`:

```hcl
enable_vpc_flow_logs = true   # Enable VPC flow logs (default)
enable_vpc_flow_logs = false  # Disable VPC flow logs
```

You can also specify `flow_logs_log_group_name` and `flow_logs_retention_in_days` for custom log group and retention settings.

**Key variables:**

- `enable_vpc_flow_logs` – Enable or disable VPC flow logs (default: true).
- `flow_logs_log_group_name` – Existing CloudWatch log group name for flow logs (optional).
- `flow_logs_retention_in_days` – Retention period for VPC flow logs.

1; Copy the sample variables file and tailor it for your environment:

   ```bash
   cd infra/terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars for environment-specific overrides
   ```

Notes on adopting existing CloudWatch Log Group

If you already have a CloudWatch Logs log group for VPC flow logs and want Terraform to use it rather than create a new one, set one of the following in your `terraform.tfvars`:

- `flow_logs_log_group_name = "/aws/vpc/vox-api-production-flow-logs"` — explicitly provide the existing log group name. The networking module will use a data source to read it.
- `adopt_existing_flow_logs = true` — tell the module to try to adopt the generated name ("/aws/vpc/${name_prefix}-flow-logs"). Use this only if the existing group matches the generated name.

When adopting, Terraform will not attempt to create the log group. This avoids "ResourceAlreadyExistsException" errors when the log group exists outside Terraform.

2; Initialize Terraform and download providers:

   ```bash
   terraform init
   ```

3; Select or create a workspace for your environment (e.g., dev, staging, prod):

   ```bash
   terraform workspace select staging || terraform workspace new staging
   ```

4; Review and apply changes:

   ```bash
   terraform plan
   terraform apply
   ```

## Module Usage

Each module is called from the root `main.tf` and receives environment-specific variables. Outputs from one module are passed as inputs to others (e.g., VPC ID from networking to ECS, IAM policy ARNs to ECS task roles, ALB outputs to ECS service).

Example module call:

```hcl
module "networking" {
  source = "./modules/networking"
  name   = local.name_prefix
  # ...other variables...
}

module "ecs" {
  source = "./modules/ecs"
  vpc_id = module.networking.vpc_id
  # ...other variables and outputs wired in...
}
```

## Environment Support & Naming

- Use Terraform workspaces for dev, staging, prod isolation.
- All resources use the `<project>-<env>-<resource>` naming convention for clarity and separation.

## Key Outputs

- `application_environment`: Map of environment variables for ECS and Celery tasks.
- `alb_dns_name`, `alb_security_group_id`, `ecs_cluster_name`, `rds_database_url`, `redis_url`, `s3_bucket_names`, etc.
- Outputs are documented in `outputs.tf` and surfaced for CI/CD and automation.

## Resource Creation Toggles

**Note:** All resources are always created. There are no flags or toggles to conditionally create resources. The infrastructure is fully declarative and modular.

## Extending Infrastructure

Add new modules under `modules/` and wire them in via the root `main.tf`. Follow the established pattern for variables and outputs.

## Important Variables

- `container_image` – Optional bootstrap image URI for ECS tasks.
- `availability_zones` – Control which AZs host subnets.
- `alb_allowed_cidrs` – Restrict incoming traffic to the ALB.
- `ecs_task_environment` – Additional environment variables for containers.
- `celery_cpu`, `celery_memory`, `celery_desired_count` – Celery worker resources.
- `frontend_url` – Base URL for password reset and CORS.
- `single_nat_gateway` – Share a single NAT gateway across AZs.
- `db_*`, `redis_*`, `s3_*`, `ecr_*` variables – Tune instance shapes, retention, encryption, and lifecycle policies.

See `variables.tf` for the complete list of tunables.

## SES Email Configuration

The infrastructure includes optional Amazon SES setup for transactional email:

### Domain Verification (Recommended)

Set `email_domain` to your domain (e.g., `yourcompany.com`) to enable domain verification and DKIM signing:

```bash
terraform apply -var="email_domain=yourcompany.com"

## Organization-Specific Compliance & Guardrails


### Compliance & Guardrails

The following compliance and security guardrails are enforced by this Terraform stack:

- **Encryption everywhere:** All data at rest and in transit is encrypted (RDS, ElastiCache, S3, ALB access logs).
- **IAM least-privilege:** All IAM roles and policies are scoped to the minimum required permissions for each service.
- **Remote state and state locking:** Terraform state is stored in S3 with DynamoDB locking to prevent concurrent changes.
- **Environment isolation:** Terraform workspaces are used to isolate dev, staging, and prod environments.
- **Review before apply:** All changes should be reviewed with `terraform plan` before applying in production.
- **Security monitoring:** CloudWatch alarms and VPC flow logs are enabled for observability and alerting.
- **Private-only data plane:** All compute, database, and cache resources run in private subnets; only the ALB is public.
- **Sensitive config management:** Passwords, secrets, and tokens are generated and injected via SSM/Secrets Manager and surfaced as outputs for CI/CD.
- **Access control:** ALB security group and allowed CIDRs restrict inbound traffic; ECS tasks do not receive public IPs.

Document any additional organization-specific requirements or controls below as needed.

Enable SES SMTP credentials by setting `create_ses_smtp_credentials = true`:

```bash
terraform apply -var="create_ses_smtp_credentials=true"
```

The SMTP username and password are exported directly as Terraform outputs. Use these in your Django `EMAIL_*` settings:

- **SMTP Host:** `email-smtp.{region}.amazonaws.com` (e.g., `email-smtp.us-east-1.amazonaws.com`)
- **SMTP Port:** `587` (TLS) or `465` (SSL)
- **SMTP Username/Password:** From the `ses_smtp_username` and `ses_smtp_password` outputs

### IAM Permissions

ECS tasks automatically receive SES send permissions via the `ses_send_email` IAM policy attached to the task role.

## Security & Reliability Highlights

- **Private-only data plane:** ECS tasks, PostgreSQL, and Redis live in private subnets. NAT gateways and VPC endpoints enable outbound access without exposing instances.
- **Managed config:** Passwords, auth tokens, and the Django secret key are generated automatically and exposed through the `application_environment` output so pipelines can inject them as environment variables.
- **Resilience:** Single-instance deployments for RDS and Redis by default (configurable to multi-AZ), ALB health checks, ECS circuit breakers, and autoscaling policies keep the service responsive to failures or load spikes.
- **Observability:** VPC flow logs and structured ECS logs land in CloudWatch; ALB access logs are delivered to an encrypted S3 bucket.

## Next Steps

- Point your domain (Route 53 or external registrar) to the ALB using the `alb_dns_name` and `alb_hosted_zone_id` outputs.
- Wire application configuration into your deployment automation by consuming the `application_environment` output (includes values such as `DATABASE_URL`, `REDIS_URL`, and `DJANGO_SECRET_KEY`).
- Push container images to the `ecr_repository_url` output and, if desired, set the `CONTAINER_IMAGE` secret used by the deploy workflow for bootstrap applies.
- Optionally extend with CloudFront, WAF, or additional services by creating new modules alongside the included ones.

---

This Terraform stack gives you a secure foundation for deploying Vox API on AWS. Review plans carefully before applying in production and layer any organization-specific guardrails or compliance controls as needed.
