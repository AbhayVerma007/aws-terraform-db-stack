# 🏗️ Terraform + Database Reliability Stack

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

Welcome to the **Terraform + Database Reliability Stack**! This repository demonstrates a robust, production-ready infrastructure setup using Infrastructure as Code (IaC) alongside a fully functional local development database environment.

## ✨ Key Features

- **☁️ AWS Infrastructure Design:** Complete architecture modeled with Terraform.
- **🐳 Local Environment:** A local PostgreSQL database stack managed with Docker Compose.
- **🛠️ Database Tooling:** Included scripts for migrations, seed data, backups, and restores.
- **🌱 Multi-Environment Configuration:** Environment-specific Terraform setups for `dev` and `prod`.
- **🤖 Automated CI/CD:** GitHub Actions workflows that automatically run Terraform validation and post `terraform plan` reviews directly as Pull Request comments.

---

## 📂 Repository Layout

<details open>
<summary><b>Folder structure</b></summary>

```text
├── infra/
│   ├── modules/
│   │   ├── network/
│   │   ├── ecs/
│   │   └── rds/
│   └── envs/
│       ├── dev/
│       └── prod/
├── db/
│   ├── migrations/
│   └── seeds/
├── scripts/
└── .github/
    └── workflows/
```
</details>

---

## 🏛️ What Is Modeled In Terraform

The AWS architecture follows this highly available design pattern:

> **`Internet -> ALB -> ECS/Fargate -> RDS`**

**Included AWS Resources:**
* VPC with public and private subnets, route tables, and an internet gateway.
* Security Groups for the ALB, ECS/Fargate, and RDS.
* ECS cluster, task definition, and service.
* Private RDS PostgreSQL instance.
* Environment-specific sizing, deletion protection, and backup retention.

*Note: The configuration is designed for `terraform fmt`, `terraform validate`, and `terraform plan`. No real deployment is required to assess this code.*

---

## 💻 Local Database Stack Setup

The local stack uses PostgreSQL in Docker Compose. It comes pre-packaged with initialization scripts, migrations (`db/migrations/001_init.sql`), and seed data (`db/seeds/001_seed.sql`).

### Prerequisites
Before getting started, ensure you have the following installed:
* [Docker](https://www.docker.com/) & Docker Compose
* [Terraform](https://www.terraform.io/) >= 1.15
* AWS credentials (configured in GitHub Actions for CI workflows)

### Step-by-Step Initialization

**1. Start the database container:**
```bash
docker compose up -d
```

**2. Run the database migrations:**
```bash
./scripts/db-migrate.sh
```

**3. Load the initial seed data:**
```bash
./scripts/db-seed.sh
```

**4. Connect to the PostgreSQL instance:**
```bash
docker exec -it tfdb-postgres psql -U appuser -d appdb
```

---

## 🔄 Backup And Restore

Maintaining database reliability is critical. Use the provided utility scripts to manage your local data snapshots.

* **Create a backup:**
    ```bash
    ./scripts/db-backup.sh
    ```
* **Restore from the latest backup:**
    ```bash
    ./scripts/db-restore.sh
    ```

<img width="1045" height="1040" alt="db-ss" src="https://github.com/user-attachments/assets/9f72e913-047a-4ee6-9630-cf536583369c" />

---

## ✅ Terraform Verification

You can manually validate the infrastructure configuration for each environment. Navigate to the desired environment directory and run the standard Terraform workflow:

```bash
cd infra/envs/dev
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -var-file=dev.tfvars
```
*(Repeat the exact same steps for `infra/envs/prod` using the `prod.tfvars` file).*

---

## 🌍 Environment Differences

The infrastructure dynamically scales and configures itself based on the target environment:

| Feature | `dev` Environment | `prod` Environment |
| :--- | :--- | :--- |
| **Sizing** | Smaller ECS and RDS instances | Larger ECS and RDS instances |
| **Backup Retention** | Shorter duration | Longer duration |
| **Deletion Protection**| `false` | `true` |

---

## 🔐 GitHub Actions & CI/CD Workflow

This repository features a reviewer-friendly GitHub Actions workflow. When a Pull Request is opened, the bot automatically formats, validates, and runs a `terraform plan`, posting the results directly in the PR comments for easy review.

**Required Repository Secrets:**
To make the Pull Request workflow run successfully, configure the following secrets in your GitHub repository settings:

* `AWS_ACCESS_KEY_ID`: Allows the AWS provider to initialize cleanly in CI.
* `AWS_SECRET_ACCESS_KEY`: Pairs with the Access Key ID.
* `TF_VAR_DB_PASSWORD`: Supplies the database password dynamically without hardcoding it into the repository.

<img width="1830" height="1895" alt="reviewer-friendly" src="https://github.com/user-attachments/assets/54144675-31c5-46ba-baf8-eea9f6c2dab1" />



*💡 Pro-Tip: If you prefer using GitHub OIDC instead of long-lived AWS keys, simply replace the credential step in the workflow with an AWS role assumption step.*

---

## 📝 General Notes

* **Local Backend:** The Terraform backend blocks are intentionally kept local by default. This ensures the repository remains immediately runnable for anyone without requiring active AWS access.
* **Database Agnostic Design:** While this workflow uses PostgreSQL, the Terraform RDS module is designed modularly and is easy to adapt to MySQL if needed.
