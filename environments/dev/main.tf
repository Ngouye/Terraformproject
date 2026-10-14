data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:La sélection est tronquée à var.az_count ci-dessous : une nouvelle AZ ne change jamais les zones utilisées
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name               = "${var.project}-${var.environment}"
  account_id         = data.aws_caller_identity.current.account_id
  azs                = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  app_log_group_name = "/ecs/${local.name}/app"
}

################################################################################
# Clé de chiffrement de l'environnement (RDS, S3, ECR, logs, SNS, secrets)
################################################################################

module "kms" {
  source = "../../modules/kms"

  alias                   = local.name
  description             = "${local.name} - chiffrement au repos"
  deletion_window_in_days = var.deletion_protection ? 30 : 7
}

################################################################################
# Réseau
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  name                     = local.name
  cidr_block               = var.vpc_cidr
  azs                      = local.azs
  single_nat_gateway       = var.single_nat_gateway
  kms_key_arn              = module.kms.key_arn
  flow_logs_retention_days = var.log_retention_days
}

module "security_groups" {
  source = "../../modules/security-groups"

  name              = local.name
  vpc_id            = module.vpc.vpc_id
  app_port          = var.container_port
  alb_ingress_cidrs = var.alb_ingress_cidrs
}

################################################################################
# Stockage
################################################################################

# Access logs de l'ALB + access logs S3. SSE-S3 car la livraison des logs ALB
# ne supporte pas SSE-KMS.
module "logs_bucket" {
  source = "../../modules/s3"

  bucket_name                       = "${local.name}-logs-${local.account_id}"
  kms_key_arn                       = null
  expiration_days                   = var.log_retention_days
  attach_elb_log_delivery_policy    = true
  attach_access_log_delivery_policy = true
  force_destroy                     = !var.deletion_protection
}

# Bucket applicatif (uploads, assets), SSE-KMS avec la clé de l'environnement.
module "assets_bucket" {
  source = "../../modules/s3"

  bucket_name       = "${local.name}-assets-${local.account_id}"
  kms_key_arn       = module.kms.key_arn
  access_log_bucket = module.logs_bucket.bucket_id
  force_destroy     = !var.deletion_protection
}

module "ecr" {
  source = "../../modules/ecr"

  name         = local.name
  kms_key_arn  = module.kms.key_arn
  force_delete = !var.deletion_protection
}

################################################################################
# Load balancer
################################################################################

module "alb" {
  source = "../../modules/alb"

  name                = local.name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  security_group_id   = module.security_groups.alb_security_group_id
  target_port         = var.container_port
  health_check_path   = var.health_check_path
  certificate_arn     = var.certificate_arn
  access_logs_bucket  = module.logs_bucket.bucket_id
  deletion_protection = var.deletion_protection
}

################################################################################
# Base de données
################################################################################

module "rds" {
  source = "../../modules/rds-postgres"

  identifier                   = "${local.name}-postgres"
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  max_allocated_storage        = var.db_max_allocated_storage
  multi_az                     = var.db_multi_az
  backup_retention_period      = var.db_backup_retention_days
  performance_insights_enabled = var.db_performance_insights
  subnet_ids                   = module.vpc.private_data_subnet_ids
  security_group_ids           = [module.security_groups.db_security_group_id]
  kms_key_arn                  = module.kms.key_arn
  log_retention_days           = var.log_retention_days
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = !var.deletion_protection
  apply_immediately            = !var.deletion_protection
}

################################################################################
# Application (IAM + ECS Fargate)
################################################################################

module "iam" {
  source = "../../modules/iam"

  name                   = local.name
  log_group_name         = local.app_log_group_name
  ecr_repository_arns    = [module.ecr.repository_arn]
  secret_arns            = [module.rds.master_user_secret_arn]
  kms_key_arns           = [module.kms.key_arn]
  s3_bucket_arns         = [module.assets_bucket.bucket_arn]
  enable_execute_command = var.enable_execute_command
}

module "ecs" {
  source = "../../modules/ecs-fargate"

  name               = local.name
  subnet_ids         = module.vpc.private_app_subnet_ids
  security_group_ids = [module.security_groups.app_security_group_id]
  target_group_arn   = module.alb.target_group_arn

  container_image  = var.container_image
  container_port   = var.container_port
  cpu              = var.app_cpu
  memory           = var.app_memory
  cpu_architecture = var.app_cpu_architecture

  desired_count          = var.app_desired_count
  min_capacity           = var.app_min_capacity
  max_capacity           = var.app_max_capacity
  use_fargate_spot       = var.use_fargate_spot
  enable_execute_command = var.enable_execute_command

  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn

  log_group_name     = local.app_log_group_name
  log_retention_days = var.log_retention_days
  kms_key_arn        = module.kms.key_arn

  environment = {
    APP_ENV       = var.environment
    DB_HOST       = module.rds.address
    DB_PORT       = tostring(module.rds.port)
    DB_NAME       = module.rds.db_name
    DB_USER       = module.rds.master_username
    DB_SSLMODE    = "require"
    ASSETS_BUCKET = module.assets_bucket.bucket_id
  }

  # Injecté au démarrage du conteneur par l'agent ECS, jamais stocké dans le state Terraform.
  secrets = {
    DB_PASSWORD = "${module.rds.master_user_secret_arn}:password::"
  }
}

################################################################################
# Observabilité
################################################################################

module "monitoring" {
  source = "../../modules/monitoring"

  name                      = local.name
  kms_key_arn               = module.kms.key_arn
  alarm_emails              = var.alarm_emails
  alb_arn_suffix            = module.alb.alb_arn_suffix
  target_group_arn_suffix   = module.alb.target_group_arn_suffix
  ecs_cluster_name          = module.ecs.cluster_name
  ecs_service_name          = module.ecs.service_name
  rds_instance_identifier   = module.rds.db_instance_identifier
  rds_connections_threshold = var.db_connections_alarm_threshold
}
