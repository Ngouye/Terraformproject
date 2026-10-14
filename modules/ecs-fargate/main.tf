data "aws_region" "current" {}

locals {
  capacity_provider = var.use_fargate_spot ? "FARGATE_SPOT" : "FARGATE"

  container_definition = {
    name                   = var.container_name
    image                  = var.container_image
    essential              = true
    readonlyRootFilesystem = var.readonly_root_filesystem

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [for k, v in var.environment : { name = k, value = v }]
    secrets     = [for k, v in var.secrets : { name = k, valueFrom = v }]

    # Espace de travail inscriptible pour que la racine reste en lecture seule.
    mountPoints = [{
      sourceVolume  = "tmp"
      containerPath = "/tmp"
      readOnly      = false
    }]

    linuxParameters = {
      initProcessEnabled = true # nettoie les processus zombies, requis par ECS Exec
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = var.container_name
      }
    }
  }
}

################################################################################
# Logs
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

################################################################################
# Cluster
################################################################################

resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = local.capacity_provider
    weight            = 1
  }
}

################################################################################
# Task definition
################################################################################

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([local.container_definition])

  tags = var.tags
}

################################################################################
# Service
################################################################################

resource "aws_ecs_service" "this" {
  name                              = "${var.name}-svc"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.desired_count
  platform_version                  = "LATEST"
  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  enable_ecs_managed_tags           = true
  propagate_tags                    = "SERVICE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # Rollback automatique quand une nouvelle révision ne devient jamais saine.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  capacity_provider_strategy {
    capacity_provider = local.capacity_provider
    weight            = 1
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags = var.tags

  lifecycle {
    # Une fois le service créé, desired_count est piloté par l'auto scaling.
    ignore_changes = [desired_count]
  }

  depends_on = [aws_ecs_cluster_capacity_providers.this]
}

################################################################################
# Auto scaling (target tracking sur le CPU et la mémoire)
################################################################################

resource "aws_appautoscaling_target" "this" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity

  tags = var.tags
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.cpu_target_utilization
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.name}-memory-target-tracking"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.memory_target_utilization
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}
