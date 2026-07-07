# Terraform + Database Reliability Stack

This repository demonstrates:

- AWS infrastructure design with Terraform
- A local PostgreSQL environment with Docker Compose
- Database migrations, seed data, backup, and restore scripts
- Environment-specific Terraform configuration for `dev` and `prod`
- A GitHub Actions workflow for Terraform validation and plan review

## Repo Layout

```text
infra/
  modules/
    network/
    ecs/
    rds/
  envs/
    dev/
    prod/
db/
  migrations/
  seeds/
scripts/
.github/workflows/
```

## What Is Modeled In Terraform

The AWS design follows:

`Internet -> ALB -> ECS/Fargate -> RDS`

Included:

- VPC with public and private subnets
- Route tables and internet gateway
- ALB security group
- ECS/Fargate security group
- RDS security group
- ECS cluster, task definition, and service
- Private RDS PostgreSQL instance
- Environment-specific sizing and backup retention

The configuration is designed for `terraform fmt`, `terraform validate`, and `terraform plan`.
No real deployment is required for this assessment.

## Local Database Stack

The local stack uses PostgreSQL in Docker Compose and includes:

- `db/migrations/001_init.sql`
- `db/seeds/001_seed.sql`
- backup script
- restore script

## Prerequisites

- Docker
- Docker Compose
- Terraform >= 1.15
- AWS credentials in GitHub Actions if you want the workflow to run `terraform plan`

## Local Database Setup

1. Start the database:

```bash
docker compose up -d
```

2. Run migrations:

```bash
./scripts/db-migrate.sh
```

3. Load seed data:

```bash
./scripts/db-seed.sh
```

4. Connect to PostgreSQL:

```bash
docker exec -it tfdb-postgres psql -U appuser -d appdb
```

## Backup And Restore

Create a backup:

```bash
./scripts/db-backup.sh
```

Restore from the latest backup:

```bash
./scripts/db-restore.sh
```

## Terraform Verification

Validate the infrastructure configuration from each environment directory:

```bash
cd infra/envs/dev
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -var-file=dev.tfvars
```

Repeat the same for `infra/envs/prod`.

## GitHub Actions Secrets

To make the Pull Request workflow run successfully, create these repository secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TF_VAR_DB_PASSWORD`

Why:

- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` let the AWS provider initialize cleanly in CI.
- `TF_VAR_DB_PASSWORD` supplies the database password without hardcoding it in the repository.

If you want to use GitHub OIDC instead of long-lived AWS keys, replace the credential step in the workflow with role assumption.

## Environment Differences

- `dev`
  - smaller ECS and RDS sizing
  - shorter RDS backup retention
  - `deletion_protection = false`

- `prod`
  - larger ECS and RDS sizing
  - longer RDS backup retention
  - `deletion_protection = true`

## Notes

- The Terraform backend blocks are intentionally local by default so the repo remains runnable without AWS access.
- The database workflow uses PostgreSQL, but the Terraform RDS module is easy to adapt to MySQL if needed.
