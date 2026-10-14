data "aws_partition" "current" {}

resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnets"
  description = "Subnets data sans route Internet - ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = var.tags
}

################################################################################
# Parameter group : TLS obligatoire + journalisation des requêtes
################################################################################

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.identifier}-"
  family      = var.parameter_group_family
  description = "Configuration PostgreSQL durcie - ${var.identifier}"

  # Refuse toute connexion non chiffrée en transit.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = tostring(var.slow_query_threshold_ms)
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Log groups créés à l'avance pour maîtriser la rétention et le chiffrement
# (sinon RDS les crée avec une rétention infinie et sans CMK).
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(var.cloudwatch_logs_exports)

  name              = "/aws/rds/instance/${var.identifier}/${each.value}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

################################################################################
# Rôle de l'Enhanced Monitoring
################################################################################

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name               = "${var.identifier}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

################################################################################
# Instance
################################################################################

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Stockage : chiffré au repos avec la CMK du projet, autoscaling activé.
  storage_type          = "gp3"
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # Identifiants : le mot de passe maître est généré, stocké et renouvelé par
  # RDS dans Secrets Manager. Il n'apparaît jamais dans le code ni dans le state.
  db_name                             = var.db_name
  username                            = var.master_username
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = var.kms_key_arn
  iam_database_authentication_enabled = true

  # Réseau : privé uniquement.
  port                   = var.port
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false
  multi_az               = var.multi_az
  parameter_group_name   = aws_db_parameter_group.this.name
  ca_cert_identifier     = "rds-ca-rsa2048-g1"

  # Sauvegardes et maintenance.
  backup_retention_period    = var.backup_retention_period
  backup_window              = var.backup_window
  maintenance_window         = var.maintenance_window
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"

  # Observabilité.
  enabled_cloudwatch_logs_exports       = var.cloudwatch_logs_exports
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.monitoring,
  ]
}
