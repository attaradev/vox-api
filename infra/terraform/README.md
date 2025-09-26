# Vox API Terraform Infrastructure

This directory contains the production-ready Terraform configuration for deploying Vox API into AWS with a secure, highly-available baseline. Key design goals include:

- All compute, databases, and caches run in private subnets; only the Application Load Balancer is public.
- Encryption everywhere: RDS, ElastiCache, S3 buckets, and Secrets Manager all enforce encryption at rest and in transit.
- Operational resilience via multi-AZ networking, redundant NAT gateways, autoscaling ECS services, and managed backing services.
- Maintainable, modular Terraform code that cleanly separates network, compute, data, and storage concerns.

## Architecture Overview

Provisioned components include:

- **Networking:** Dedicated VPC with public, private application, and private data subnets across multiple AZs; internet gateway, NAT gateways, VPC flow logs, and private VPC endpoints for AWS APIs frequently used by the workload.
- **Compute:** AWS Fargate/ECS cluster with an autoscaled service fronted by an Application Load Balancer. ALB access logs are retained in a locked-down S3 bucket.
- **Data:** Amazon RDS for PostgreSQL (multi-AZ) and ElastiCache for Redis (encryption enabled). Credentials and auth tokens are rotated automatically and stored securely in AWS Secrets Manager.
- **Storage:** Private S3 buckets for static assets and media uploads with versioning, lifecycle policies, and default encryption.
- **Container Registry:** Private Amazon ECR repository with scan-on-push, tag immutability, and lifecycle rules for pruning older images.
- **Secrets & Config:** Dedicated Secrets Manager entries for the Django secret key, database credentials, and Redis connection information, including ready-to-use connection strings that are wired into the ECS task definition by default.

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
├── locals.tf              # Shared name/tag helpers
├── main.tf                # Root module wiring all components together
├── outputs.tf             # Surface key connection details and secrets
├── providers.tf           # AWS provider configuration with default tags
├── variables.tf           # Root module inputs
├── versions.tf            # Terraform & provider version constraints
├── terraform.tfvars.example
└── modules/
    ├── ecs_service/       # ECS cluster, service, ALB, IAM
    ├── ecr_repository/    # Private ECR repo with lifecycle policy
    ├── network/           # VPC, subnets, routing, endpoints, flow logs
    ├── rds/               # PostgreSQL instance + credentials secret
    ├── redis/             # ElastiCache replication group + secret
    └── s3_buckets/        # Static & media buckets with encryption
```

Each module exposes outputs used by the top-level configuration and can be re-used independently if you need custom compositions later.

## Getting Started

1. Copy the sample variables file and tailor it for the environment you are provisioning:

   ```bash
   cd infra/terraform
   cp terraform.tfvars.example terraform.tfvars
   # edit terraform.tfvars with real image tags, secret ARNs, etc.
   ```

2. Initialize Terraform and download providers:

   ```bash
   terraform init
   ```

3. Select (or create) the workspace that matches your environment name. The deploy workflow uses the same convention:

   ```bash
   terraform workspace select staging || terraform workspace new staging
   ```

4. Review changes to be applied:

   ```bash
   terraform plan
   ```

5. Apply the infrastructure when ready:

   ```bash
   terraform apply
   ```

After the apply succeeds, use the outputs to configure DNS (ALB details), update application secrets, and connect external services.

## Important Variables

- `container_image` – optional bootstrap image URI; if omitted, the ECS service uses the repository provisioned by Terraform with a placeholder tag until the deployment workflow pushes a real image.
- `availability_zones` – override to control which AZs host the subnets (defaults to the first two).
- `alb_allowed_cidrs` – restrict incoming traffic to the load balancer.
- `ecs_task_environment` – inject additional environment variables into the running containers.
- `ecs_task_secrets` – optional overrides for the default database/redis/Django secrets that Terraform provisions automatically (provide unique secret names per entry).
- `db_*` and `redis_*` variables – tune instance shapes, retention, or password overrides.
- `s3_force_destroy` – defaults to `false` to protect data; set `true` only in ephemeral environments.
- `ecr_*` variables – adjust tag mutability, scanning, encryption, or lifecycle policy for the container registry.

See `variables.tf` for the complete list of tunables.

## Security & Reliability Highlights

- **Private-only data plane:** ECS tasks, PostgreSQL, and Redis live in private subnets. NAT gateways and VPC endpoints enable outbound access without exposing instances.
- **Managed secrets:** Passwords, auth tokens, and the Django secret key are generated automatically and persisted in Secrets Manager.
- **Resilience:** Multi-AZ deployments for RDS and Redis, ALB health checks, ECS circuit breakers, and autoscaling policies keep the service responsive to failures or load spikes.
- **Observability:** VPC flow logs and structured ECS logs land in CloudWatch; ALB access logs are delivered to an encrypted S3 bucket.

## Next Steps

- Point your domain (Route 53 or external registrar) to the ALB using the `alb_dns_name` and `alb_hosted_zone_id` outputs.
- Wire application secrets/urls to your deployment automation using the emitted Secrets Manager ARNs (the Terraform defaults already supply `DATABASE_URL`, `REDIS_URL`, and `DJANGO_SECRET_KEY` to the ECS service).
- Push container images to the `ecr_repository_url` output and, if desired, set the `CONTAINER_IMAGE` secret used by the deploy workflow for bootstrap applies.
- Optionally extend with CloudFront, WAF, or additional services by creating new modules alongside the included ones.

---

This Terraform stack gives you a secure foundation for deploying Vox API on AWS. Review plans carefully before applying in production and layer any organization-specific guardrails or compliance controls as needed.
