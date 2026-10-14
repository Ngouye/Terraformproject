data "aws_region" "current" {}

locals {
  region = data.aws_region.current.region

  alb_dimensions = { LoadBalancer = var.alb_arn_suffix }
  tg_dimensions  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
  ecs_dimensions = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  rds_dimensions = { DBInstanceIdentifier = var.rds_instance_identifier }

  # Toutes les alarmes ont la même structure : un seul bloc de ressource les crée toutes.
  alarms = {
    alb-elb-5xx = {
      description        = "Le load balancer renvoie lui-même des erreurs 5XX (aucune cible saine, mauvaise configuration)."
      namespace          = "AWS/ApplicationELB"
      metric_name        = "HTTPCode_ELB_5XX_Count"
      statistic          = "Sum"
      extended_statistic = null
      comparison         = "GreaterThanThreshold"
      threshold          = var.alb_5xx_threshold
      period             = 300
      evaluation_periods = 1
      missing_data       = "notBreaching"
      dimensions         = local.alb_dimensions
    }
    alb-target-5xx = {
      description        = "L'application renvoie des erreurs 5XX."
      namespace          = "AWS/ApplicationELB"
      metric_name        = "HTTPCode_Target_5XX_Count"
      statistic          = "Sum"
      extended_statistic = null
      comparison         = "GreaterThanThreshold"
      threshold          = var.alb_5xx_threshold
      period             = 300
      evaluation_periods = 1
      missing_data       = "notBreaching"
      dimensions         = local.tg_dimensions
    }
    alb-unhealthy-targets = {
      description        = "Au moins une tâche ECS échoue au health check de l'ALB."
      namespace          = "AWS/ApplicationELB"
      metric_name        = "UnHealthyHostCount"
      statistic          = "Maximum"
      extended_statistic = null
      comparison         = "GreaterThanThreshold"
      threshold          = 0
      period             = 60
      evaluation_periods = 3
      missing_data       = "notBreaching"
      dimensions         = local.tg_dimensions
    }
    alb-latency-p95 = {
      description        = "Le 95e percentile du temps de réponse dépasse ${var.alb_latency_p95_seconds} s."
      namespace          = "AWS/ApplicationELB"
      metric_name        = "TargetResponseTime"
      statistic          = null
      extended_statistic = "p95"
      comparison         = "GreaterThanThreshold"
      threshold          = var.alb_latency_p95_seconds
      period             = 300
      evaluation_periods = 3
      missing_data       = "notBreaching"
      dimensions         = local.alb_dimensions
    }
    ecs-cpu-high = {
      description        = "CPU du service ECS au-dessus de ${var.ecs_cpu_threshold} % (auto scaling au maximum ?)."
      namespace          = "AWS/ECS"
      metric_name        = "CPUUtilization"
      statistic          = "Average"
      extended_statistic = null
      comparison         = "GreaterThanThreshold"
      threshold          = var.ecs_cpu_threshold
      period             = 300
      evaluation_periods = 2
      missing_data       = "notBreaching"
      dimensions         = local.ecs_dimensions
    }
    ecs-memory-high = {
      description        = "Mémoire du service ECS au-dessus de ${var.ecs_memory_threshold} %."
      namespace          = "AWS/ECS"
      metric_name        = "MemoryUtilization"
      statistic          = "Average"
      extended_statistic = null
      comparison         = "GreaterThanThreshold"
      threshold          = var.ecs_memory_threshold
      period             = 300
      evaluation_periods = 2
      missing_data       = "notBreaching"
      dimensions         = local.ecs_dimensions
    }
    ecs-no-running-task = {
      description        = "Aucune tâche ECS en cours d'exécution : l'application est indisponible."
      namespace          = "ECS/ContainerInsights"
      metric_name        = "RunningTaskCount"
      statistic          = "Minimum"
      extended_statistic = null
      comparison         = "LessThanThreshold"
      threshold          = 1
      period             = 60
      evaluation_periods = 3
      missing_data       = "breaching"
      dimensions         = local.ecs_dimensions
    }
    rds-cpu-high = {
      description        = "CPU RDS au-dessus de ${var.rds_cpu_threshold} %."
      namespace          = "AWS/RDS"
      metric_name        = "CPUUtilization"
      statistic          = "Average"
      extended_statistic = null
      comparison         = "GreaterThanThreshold"
      threshold          = var.rds_cpu_threshold
      period             = 300
      evaluation_periods = 3
      missing_data       = "notBreaching"
      dimensions         = local.rds_dimensions
    }
    rds-free-storage-low = {
      description        = "Stockage libre RDS sous ${var.rds_free_storage_threshold_gb} Gio."
      namespace          = "AWS/RDS"
      metric_name        = "FreeStorageSpace"
      statistic          = "Minimum"
      extended_statistic = null
      comparison         = "LessThanThreshold"
      threshold          = var.rds_free_storage_threshold_gb * 1024 * 1024 * 1024
      period             = 300
      evaluation_periods = 1
      missing_data       = "notBreaching"
      dimensions         = local.rds_dimensions
    }
    rds-freeable-memory-low = {
      description        = "Mémoire disponible RDS sous ${var.rds_freeable_memory_threshold_mb} Mio."
      namespace          = "AWS/RDS"
      metric_name        = "FreeableMemory"
      statistic          = "Average"
      extended_statistic = null
      comparison         = "LessThanThreshold"
      threshold          = var.rds_freeable_memory_threshold_mb * 1024 * 1024
      period             = 300
      evaluation_periods = 3
      missing_data       = "notBreaching"
      dimensions         = local.rds_dimensions
    }
    rds-connections-high = {
      description        = "Connexions RDS au-dessus de ${var.rds_connections_threshold}."
      namespace          = "AWS/RDS"
      metric_name        = "DatabaseConnections"
      statistic          = "Average"
      extended_statistic = null
      comparison         = "GreaterThanThreshold"
      threshold          = var.rds_connections_threshold
      period             = 300
      evaluation_periods = 2
      missing_data       = "notBreaching"
      dimensions         = local.rds_dimensions
    }
  }
}

################################################################################
# Notifications
################################################################################

resource "aws_sns_topic" "alarms" {
  name              = "${var.name}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = var.tags
}

# Chaque adresse reçoit un e-mail de confirmation qu'il faut accepter.
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alarm_emails)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

################################################################################
# Alarmes
################################################################################

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${var.name}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  statistic           = each.value.statistic
  extended_statistic  = each.value.extended_statistic
  comparison_operator = each.value.comparison
  threshold           = each.value.threshold
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  treat_missing_data  = each.value.missing_data
  dimensions          = each.value.dimensions

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}

################################################################################
# Dashboard
################################################################################

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB - Requêtes et erreurs"
          region = local.region
          stat   = "Sum"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB - Temps de réponse p50 / p95 (s)"
          region = local.region
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50" }],
            ["...", { stat = "p95" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS - CPU et mémoire (%)"
          region = local.region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS - Tâches en cours / souhaitées"
          region = local.region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            [".", "DesiredTaskCount", ".", ".", ".", "."],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS - CPU (%) et connexions"
          region = local.region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_identifier],
            [".", "DatabaseConnections", ".", ".", { yAxis = "right" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS - Stockage libre et mémoire disponible (octets)"
          region = local.region
          stat   = "Minimum"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_identifier],
            [".", "FreeableMemory", ".", "."],
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 18
        width  = 24
        height = 4
        properties = {
          title  = "Alarmes"
          alarms = [for alarm in aws_cloudwatch_metric_alarm.this : alarm.arn]
        }
      },
    ]
  })
}
