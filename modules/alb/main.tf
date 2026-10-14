locals {
  https_enabled = var.certificate_arn != null
}

resource "aws_lb" "this" {
  #checkov:skip=CKV2_AWS_28:WAF prévu dans la roadmap (coût) ; l'ALB est protégé par des Security Groups restrictifs
  name                       = "${var.name}-alb"
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [var.security_group_id]
  subnets                    = var.public_subnet_ids
  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.deletion_protection
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"

  dynamic "access_logs" {
    for_each = var.access_logs_bucket == null ? [] : [var.access_logs_bucket]

    content {
      bucket  = access_logs.value
      prefix  = "alb"
      enabled = true
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-alb" })
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378:Le TLS est terminé sur l'ALB ; le trafic ALB -> tâches reste dans les subnets privés, filtré par les Security Groups
  name                 = "${var.name}-tg"
  port                 = var.target_port
  protocol             = "HTTP"
  target_type          = "ip" # obligatoire avec Fargate (mode réseau awsvpc)
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, { Name = "${var.name}-tg" })
}

# Port 80 : redirection permanente vers HTTPS quand un certificat est fourni,
# sinon transfert direct vers les cibles (dev sans nom de domaine).
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:HTTP redirige vers HTTPS dès que certificate_arn est défini (obligatoire en prod)
  #checkov:skip=CKV_AWS_103:La politique TLS est appliquée sur le listener HTTPS
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.https_enabled ? "redirect" : "forward"
    target_group_arn = local.https_enabled ? null : aws_lb_target_group.this.arn

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}
