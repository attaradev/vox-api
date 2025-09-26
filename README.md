# Vox API

**Vox API** is a modular, production-ready backend for running team-based polls. It ships with Django REST Framework APIs, multi-tenant account management, subscription billing hooks, and background workers so you can launch and scale voting platforms quickly.

## Features

- Multi-tenant accounts with role management, tier limits, and audit logging for compliance
- Poll creation, choice management, and secure voting flows backed by token verification
- Subscription billing powered by dj-stripe with webhook handlers and usage tracking
- Celery + Redis workers for async jobs (email, notifications, heavy tasks) and Flower monitoring
- Sentry-ready error hooks, health checks, and Docker-first tooling for dependable deployments
- **Modular Terraform infrastructure for AWS cloud deployment**

## Prerequisites

- Docker and the Docker Compose plugin (recommended workflow)
- Optional: Python 3.12+ and Redis/Postgres if you prefer to run services without Docker
- **Terraform 1.0+ and AWS CLI for cloud infrastructure**

## Quick Start (Docker)

1. Clone the project

   ```bash
   git clone https://github.com/attaradev/vox-api.git
   cd vox-api
   ```

2. Copy the sample environment and update secrets

   ```bash
   cp .env.example .env
   # edit .env with your credentials
   ```

3. Launch the stack

   ```bash
   docker compose up --build
   ```

   The entrypoint waits for Postgres and applies migrations automatically.
4. Create an admin user

   ```bash
   docker compose exec api python manage.py createsuperuser
   ```

5. Explore the services
   - API root & health check: <http://localhost:8000/>
   - Django admin: <http://localhost:8000/admin/>
   - Interactive API docs: <http://localhost:8000/api/docs/>
   - OpenAPI schema: <http://localhost:8000/api/schema/>

### Background workers & monitoring

```bash
docker compose up -d celery flower
```

- Celery worker queues jobs and respects tier limits (`RUN_DB_MIGRATIONS=0` keeps worker light).
- Flower dashboard is available at <http://localhost:5555/>.

### Common Docker commands

- Stop and remove containers: `docker compose down`
- Tail service logs: `docker compose logs -f api`
- Run a management command: `docker compose exec api python manage.py migrate`

## Cloud Infrastructure (Terraform)

This project ships with modular Terraform code for secure AWS deployment. See `infra/terraform/README.md` for full instructions.

**Remote state backend:**

- S3 bucket: `vox-api-terraform-state` (must be created before `terraform init`)
- DynamoDB table: `vox-api-terraform-lock` (for state locking)

**Provisioned resources:**

- VPC, subnets, NAT gateway, endpoints, flow logs
- ECS cluster, security groups, IAM roles
- RDS (Postgres), ElastiCache (Redis)
- S3 buckets for media/static and logs
- ALB (Application Load Balancer)
- CloudWatch log groups
- Secrets Manager for credentials

**Outputs for domain setup:**

- The ALB module outputs `alb_hosted_zone_id` and `alb_dns_name` for DNS and domain configuration. Example:

  ```sh
  terraform output alb_hosted_zone_id
  terraform output alb_dns_name
  ```

  Use these values to set up your custom domain or CNAME records.

**Onboarding steps:**

1. Create the S3 bucket and DynamoDB table for state backend (see infra README).
2. Run `terraform init`, `terraform plan`, and `terraform apply` in `infra/terraform`.
3. Use the outputs to configure your DNS/domain and connect your app to cloud resources.

## Local Development Without Docker

1. Create a virtual environment and install dependencies

   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

2. Provide environment variables (copy `.env.example` and adjust hosts or database URLs).
3. Run service prerequisites (Postgres + Redis) locally or via containers.
4. Apply migrations and start the server

   ```bash
   python manage.py migrate
   python manage.py runserver 0.0.0.0:8000
   ```

5. Start Celery if you need background jobs

   ```bash
   celery -A vox_api worker --loglevel=info
   ```

## Configuration

| Variable | Description |
| --- | --- |
| `DJANGO_SECRET_KEY` | Django secret key; replace before deploying |
| `DJANGO_ENV` | `development` (default) or `production` |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated list of allowed hosts |
| `POSTGRES_*` | Connection settings for the Postgres service |
| `DATABASE_URL` | Optional full DSN for direct connections |
| `CELERY_BROKER_URL` / `CELERY_RESULT_BACKEND` | Celery broker/result backend (defaults to in-memory; set real services for production) |
| `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD` | SMTP credentials for transactional email |
| `FRONTEND_URL` | Frontend base URL used in password reset links |

## Project Layout

| Path | Purpose |
| --- | --- |
| `accounts/` | Account, tier, role, and membership APIs |
| `auth/` | Registration, login, and password reset endpoints |
| `billing/` | Subscription, invoice, payment APIs and Stripe webhooks |
| `core/` | Shared utilities, the `AuditLog` model, and admin registrations |
| `polls/` | Poll, choice, and voter token flows |
| `vox_api/` | Django project settings, URLs, Celery app, and health checks |
| `compose.yml` | Docker Compose services (API, Celery, Flower, Postgres, Redis) |
| `Dockerfile` | Runtime image based on Python 3.12-slim |
| `docker-entrypoint.sh` | Waits for Postgres and applies migrations before boot |
| `Makefile` | Shortcuts for install, format, lint, test, and pre-commit |
| `.env.example` | Sample environment configuration |

## API Surface

This project uses `drf-spectacular` to generate OpenAPI schemas. Browse the interactive documentation at `/api/docs/` for the latest endpoints. Example categories include:

- Authentication: `POST /api/auth/register/`, `POST /api/auth/login/`, password reset flows
- Accounts & teams: `GET/POST /api/accounts/`, tier management, account roles, permissions
- Polling: `GET/POST /api/polls/`, manage choices via `/api/polls/<id>/choices/`, cast votes at `/api/polls/<id>/votes/`
- Billing: `GET/POST /api/billing/subscriptions/`, invoices, payments, Stripe webhook receiver

## Background Jobs & Email

- Celery workers process asynchronous tasks such as transactional emails and audit events.
- Celery defaults to the in-memory broker/result backend for local development; point `CELERY_BROKER_URL` and `CELERY_RESULT_BACKEND` at Redis or another durable service in production.
- Flower offers live worker monitoring and task introspection at `http://localhost:5555/`.
- Email is handled via Django's email backend; set SMTP credentials in `.env`.

## Observability & Auditing

- Sentry SDK is available to capture Celery failures; initialize `sentry_sdk` (e.g., during startup) and provide a DSN to forward exceptions.
- `core.models.AuditLog` records key events and is exposed in the Django admin for review.
- `/` returns a simple health check; Docker health checks rely on it for container readiness.

## Testing & Quality

- `pytest` powers the automated test suite (`pytest.ini` configures strict warnings and Django settings).
- `flake8`, `black`, and `isort` enforce style and formatting.
- The `Makefile` provides shortcuts:
  - `make install`
  - `make format`
  - `make lint`
  - `make test`
  - `make pre-commit`

## License

MIT License
