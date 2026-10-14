################################################################################
# Security Groups restrictifs, chaînés par référence (aucun CIDR entre tiers) :
#
#   Internet --80/443--> ALB --app_port--> tâches ECS --db_port--> RDS
#
# Chaque règle est explicite et décrite. Terraform supprime la règle AWS par
# défaut « allow all egress » des Security Groups qu'il crée : tout ce qui
# n'est pas listé ici est refusé.
#
# Note : AWS n'accepte ni accents ni apostrophes dans les descriptions de
# Security Groups et de règles, d'où le français sans accents ci-dessous.
################################################################################

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "Load balancer public - HTTP et HTTPS depuis Internet"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${var.name}-app-"
  description = "Conteneurs ECS Fargate - joignables uniquement depuis le load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-app-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "RDS PostgreSQL - joignable uniquement depuis les conteneurs ECS"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-db-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# ALB
################################################################################

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS depuis ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:Le port 80 ne sert qu'une redirection permanente vers HTTPS dès qu'un certificat est configuré
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP depuis ${each.value} (redirection vers HTTPS)"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Trafic et health checks vers les conteneurs ECS"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

################################################################################
# Application (tâches ECS)
################################################################################

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Port applicatif depuis le load balancer uniquement"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS vers les API AWS (ECR, CloudWatch Logs, Secrets Manager, S3) et les registres"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "PostgreSQL vers la base RDS"
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}

################################################################################
# Base de données (aucune règle de sortie : tout trafic sortant est refusé)
################################################################################

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL depuis les conteneurs ECS uniquement"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}
