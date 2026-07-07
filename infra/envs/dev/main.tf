provider "aws" {
  region = var.aws_region
}

module "network" {
  source               = "../../modules/network"
  name                 = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "rds" {
  source                  = "../../modules/rds"
  name                    = "${var.project_name}-db"
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  ecs_security_group_id   = module.ecs.ecs_security_group_id
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
}

module "ecs" {
  source             = "../../modules/ecs"
  name               = var.project_name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  container_image    = var.container_image
  desired_count      = var.desired_count
  cpu                = var.cpu
  memory             = var.memory
}

# trigger workflow test