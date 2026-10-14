################################################################################
# Général
################################################################################

variable "aws_region" {
  description = "Région AWS de l'environnement."
  type        = string
  default     = "eu-west-3"
}

variable "project" {
  description = "Nom du projet, préfixe de toutes les ressources."
  type        = string
  default     = "iac-portfolio"
}

variable "environment" {
  description = "Nom de l'environnement."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit valoir dev, staging ou prod."
  }
}

variable "owner" {
  description = "Équipe ou personne responsable des ressources (tag Owner)."
  type        = string
  default     = "platform-team"
}

variable "deletion_protection" {
  description = "Protéger les ressources avec état (ALB, RDS, buckets, ECR) contre la suppression et conserver un snapshot final de la base."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Durée de rétention de tous les logs (log groups CloudWatch et bucket de logs)."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days doit être une durée de rétention acceptée par CloudWatch Logs."
  }
}

################################################################################
# Réseau
################################################################################

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "Nombre de zones de disponibilité utilisées."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Partager une seule NAT Gateway entre toutes les AZ (moins cher, pas hautement disponible)."
  type        = bool
  default     = false
}

variable "alb_ingress_cidrs" {
  description = "Blocs CIDR autorisés à joindre le load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "Certificat ACM pour le HTTPS. Null = HTTP uniquement (acceptable en dev seulement)."
  type        = string
  default     = null
}

################################################################################
# Application
################################################################################

variable "container_image" {
  description = "Image déployée sur ECS (pousser votre propre image dans le dépôt ECR créé par cette stack)."
  type        = string
}

variable "container_port" {
  description = "Port d'écoute du conteneur."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Chemin du health check de l'application."
  type        = string
  default     = "/"
}

variable "app_cpu" {
  description = "Unités CPU de la tâche."
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "Mémoire de la tâche (Mio)."
  type        = number
  default     = 512
}

variable "app_cpu_architecture" {
  description = "X86_64 ou ARM64."
  type        = string
  default     = "X86_64"
}

variable "app_desired_count" {
  description = "Nombre initial de tâches."
  type        = number
  default     = 2
}

variable "app_min_capacity" {
  description = "Nombre minimal de tâches."
  type        = number
  default     = 2
}

variable "app_max_capacity" {
  description = "Nombre maximal de tâches."
  type        = number
  default     = 6
}

variable "use_fargate_spot" {
  description = "Exécuter les tâches sur Fargate Spot."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Activer ECS Exec pour le débogage."
  type        = bool
  default     = false
}

################################################################################
# Base de données
################################################################################

variable "db_instance_class" {
  description = "Classe d'instance RDS."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Stockage initial (Gio)."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Stockage maximal pour l'autoscaling (Gio)."
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Déployer une instance de secours Multi-AZ."
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Durée de conservation des sauvegardes automatiques (jours)."
  type        = number
  default     = 7
}

variable "db_performance_insights" {
  description = "Activer Performance Insights."
  type        = bool
  default     = false
}

variable "db_connections_alarm_threshold" {
  description = "Nombre de connexions à la base qui déclenche une alarme (dépend de la taille de l'instance)."
  type        = number
  default     = 80
}

################################################################################
# Supervision
################################################################################

variable "alarm_emails" {
  description = "Adresses e-mail qui reçoivent les alarmes CloudWatch."
  type        = list(string)
  default     = []
}
