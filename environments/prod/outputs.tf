output "app_url" {
  description = "URL publique de l'application."
  value       = "${module.alb.https_enabled ? "https" : "http"}://${module.alb.alb_dns_name}"
}

output "alb_dns_name" {
  description = "Nom DNS du load balancer (cible de votre enregistrement CNAME ou alias)."
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "Dépôt ECR dans lequel pousser l'image de l'application."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Nom du cluster ECS."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Nom du service ECS."
  value       = module.ecs.service_name
}

output "app_log_group" {
  description = "Log group CloudWatch de l'application."
  value       = module.ecs.log_group_name
}

output "rds_endpoint" {
  description = "Endpoint privé de la base PostgreSQL."
  value       = "${module.rds.address}:${module.rds.port}"
}

output "rds_master_secret_arn" {
  description = "Secret Secrets Manager qui contient les identifiants maîtres de la base."
  value       = module.rds.master_user_secret_arn
}

output "assets_bucket_name" {
  description = "Bucket S3 de l'application."
  value       = module.assets_bucket.bucket_id
}

output "logs_bucket_name" {
  description = "Bucket S3 qui reçoit les access logs de l'ALB et de S3."
  value       = module.logs_bucket.bucket_id
}

output "vpc_id" {
  description = "Identifiant du VPC."
  value       = module.vpc.vpc_id
}

output "nat_public_ips" {
  description = "IP de sortie de l'application (à autoriser chez les API tierces)."
  value       = module.vpc.nat_public_ips
}

output "alarms_topic_arn" {
  description = "Topic SNS qui reçoit les alarmes CloudWatch."
  value       = module.monitoring.sns_topic_arn
}

output "dashboard_url" {
  description = "Dashboard CloudWatch de l'environnement."
  value       = module.monitoring.dashboard_url
}
