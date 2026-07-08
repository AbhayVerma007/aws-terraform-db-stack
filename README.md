# 🏗️ Terraform + Database Reliability Stack

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

Welcome to the **Terraform + Database Reliability Stack**! This repository demonstrates a robust, production-ready infrastructure setup using Infrastructure as Code (IaC) alongside a fully functional local development database environment..

## ✨ Key Features

- **☁️ AWS Infrastructure Design:** Complete architecture modeled with Terraform.
- **🐳 Local Environment:** A local PostgreSQL database stack managed with Docker Compose.
- **🛠️ Database Tooling:** Included scripts for migrations, seed data, backups, and restores.
- **🌱 Multi-Environment Configuration:** Environment-specific Terraform setups for `dev` and `prod`.
- **🤖 Automated CI/CD:** GitHub Actions workflows that automatically run Terraform validation and post `terraform plan` reviews directly as Pull Request comments.


## ✅ Submission Snapshot

| Area | Included |
| --- | --- |
| Terraform modules | `network`, `ecs`, `rds` |
| Environments | `dev`, `prod` |
| Local database | PostgreSQL 16 with Docker Compose |
| Seeded bookings | `120` |
| Seeded booking events | `61` from the shared verification run |
| Query optimization | Composite index on `hotel_bookings` |
| CI review flow | PR comment + plan artifact |

## 📂 Repository Layout

<details open>
<summary><b>Folder structure</b></summary>

```text
├── .github/workflows/terraform.yml
├── docker-compose.yml
├── db/
│   ├── migrations/001_init.sql
│   └── seeds/002_seed.sql
├── infra/
│   ├── envs/
│   │   ├── dev/
│   │   └── prod/
│   └── modules/
│       ├── ecs/
│       ├── network/
│       └── rds/
└── scripts/
    ├── db-backup.sh
    ├── db-common.sh
    ├── db-migrate.sh
    ├── db-restore.sh
    └── db-seed.sh
```

## 1. 🏛️ What Is Modeled In Terraform

The Terraform code models the required AWS architecture:

`Internet -> ALB -> ECS/Fargate -> RDS`

It includes:

- VPC with public and private subnets
- Security groups for ALB, ECS/Fargate, and RDS
- ECS cluster, task definition, and service
- Private RDS PostgreSQL instance
- RDS access limited to the ECS security group
- Placeholder application image using `nginx:1.27-alpine`

The code is intended to be realistic and production-oriented, while remaining reviewable without performing a real AWS deployment.

## 2. Environment Handling

Terraform is split into reusable modules and two environment examples:

- `infra/modules/network`
- `infra/modules/ecs`
- `infra/modules/rds`
- `infra/envs/dev`
- `infra/envs/prod`

Each environment has its own:

- `variables.tf`
- `backend.tf`
- environment-specific `tfvars`
- sizing configuration
- backup retention settings
- deletion protection settings

Environment differences:

| Setting | `dev` | `prod` |
| --- | --- | --- |
| Project name | `tfdb-dev` | `tfdb-prod` |
| Container image | `nginx:1.27-alpine` | `nginx:1.27-alpine` |
| ECS desired count | `1` | `2` |
| ECS CPU | `256` | `512` |
| ECS memory | `512` | `1024` |
| DB instance class | `db.t3.micro` | `db.t3.small` |
| DB storage | `20` GB | `50` GB |
| Backup retention | `3` days | `14` days |
| Deletion protection | `false` | `true` |

```

## 3. GitHub Actions Terraform Plan

The repository includes a workflow at `.github/workflows/terraform.yml`.

On pull requests affecting Terraform files, the workflow runs for both `dev` and `prod` and performs:

- `terraform fmt -check -recursive infra`
- `terraform init`
- `terraform validate`
- `terraform plan -refresh=false -var-file=<env>.tfvars`

The plan is exposed in two reviewer-friendly ways:

- PR comment with the rendered plan output
- uploaded workflow artifact containing the saved plan

Required repository secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TF_VAR_DB_PASSWORD`

## 4. 💻 Local Database Setup

Start the database:

```bash
docker compose up -d
```

Apply migrations:

```bash
./scripts/db-migrate.sh
```

Load seed data:

```bash
./scripts/db-seed.sh
```

Connect to PostgreSQL manually:

```bash
docker exec -it tfdb-postgres psql -U appuser -d appdb
```

## 5. Database Schema

The migration file creates the two required tables.

### `hotel_bookings`

```sql
hotel_bookings (
  id UUID PRIMARY KEY,
  org_id UUID NOT NULL,
  hotel_id VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  checkin_date DATE NOT NULL,
  checkout_date DATE NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL
)
```

### `booking_events`

```sql
booking_events (
  id BIGSERIAL PRIMARY KEY,
  booking_id UUID NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL
)
```

## 6. 🚀 Seed Data and Query Optimization

The seed file inserts:

- `120` hotel bookings
- multiple cities: `delhi`, `mumbai`, `bangalore`, `pune`
- multiple organizations
- multiple statuses: `CONFIRMED`, `CANCELLED`, `PENDING`
- booking events for roughly half of the bookings

From the local verification run:

- `hotel_bookings`: `120`
- `booking_events`: `61`

Observed city distribution:

- `bangalore`: `27`
- `delhi`: `34`
- `mumbai`: `34`
- `pune`: `25`

Required query:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Index added for the query:

```sql
CREATE INDEX idx_hotel_bookings_query
ON hotel_bookings(city, created_at, org_id, status);
```

Index rationale:

- `city` matches the leading equality filter
- `created_at` supports the time-range filter
- `org_id` and `status` align with the grouping pattern after filtering

## 7. 🔄 Backup and Restore

Create a compressed timestamped backup:

```bash
./scripts/db-backup.sh
```

This writes files in the format:

```text
backup/appdb-YYYYMMDD-HHMMSS.sql.gz
```

Restore the latest available backup:

```bash
./scripts/db-restore.sh
```

Restore a specific backup file:

```bash
./scripts/db-restore.sh backup/appdb-20260708-031559.sql.gz
```

## 8. ✅ Verification Steps

### Terraform

Validate `dev`:

```bash
cd infra/envs/dev
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -refresh=false -var-file=dev.tfvars
```

Validate `prod`:

```bash
cd infra/envs/prod
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -refresh=false -var-file=prod.tfvars
```
<img width="1830" height="1895" alt="reviewer-friendly" src="https://github.com/user-attachments/assets/c6334b28-a485-4727-8b49-3c1877a92a71" />

---
### Database

Start and initialize:

```bash
docker compose up -d
./scripts/db-migrate.sh
./scripts/db-seed.sh
```

Verify row counts:

```bash
docker exec -it tfdb-postgres psql -U appuser -d appdb -c "SELECT COUNT(*) FROM hotel_bookings;"
docker exec -it tfdb-postgres psql -U appuser -d appdb -c "SELECT COUNT(*) FROM booking_events;"
```

Verify city distribution:

```bash
docker exec -it tfdb-postgres psql -U appuser -d appdb -c "SELECT city, COUNT(*) FROM hotel_bookings GROUP BY city ORDER BY city;"
```

Verify the required aggregation query:

```bash
docker exec -it tfdb-postgres psql -U appuser -d appdb -c "SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status;"
```

### 🔄 Backup and Restore

Create and restore a backup:

```bash
./scripts/db-backup.sh
./scripts/db-restore.sh
```

To confirm that restore succeeded, rerun the count checks after restore and verify that the data remains present and consistent:

```bash
docker exec -it tfdb-postgres psql -U appuser -d appdb -c "SELECT COUNT(*) FROM hotel_bookings;"
docker exec -it tfdb-postgres psql -U appuser -d appdb -c "SELECT COUNT(*) FROM booking_events;"
```

Expected values from the shared verification run:

- `hotel_bookings = 120`
- `booking_events = 61`

<img width="1045" height="1040" alt="Screenshot From 2026-07-08 03-31-31" src="https://github.com/user-attachments/assets/9c5791aa-a7d9-4339-924a-34b1a2c10076" />

---