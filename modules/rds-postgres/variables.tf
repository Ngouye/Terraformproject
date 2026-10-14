variable "identifier" {
  description = "Identifiant de l'instance RDS."
  type        = string
}

variable "engine_version" {
  description = "Version de PostgreSQL. Une version majeure (ex. \"17\") laisse RDS appliquer automatiquement les mises à jour mineures."
  type        = string
  default     = "17"
}

variable "parameter_group_family" {
  description = "Famille du parameter group, correspondant à engine_version."
  type        = string
  default     = "postgres17"
}

variable "instance_class" {
  description = "Classe d'instance (ex. db.t4g.micro en dev, db.m7g.large en prod)."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Stockage initial en Gio."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Limite haute de l'autoscaling du stockage en Gio."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Nom de la base créée au lancement."
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Nom de l'utilisateur maître (le mot de passe est géré par RDS dans Secrets Manager)."
  type        = string
  default     = "app_admin"
}

variable "port" {
  description = "Port de la base de données."
  type        = number
  default     = 5432
}

variable "subnet_ids" {
  description = "Subnets isolés du DB subnet group (au moins 2 AZ)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Groups attachés à l'instance."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "Clé KMS qui chiffre le stockage, les snapshots, le secret maître, Performance Insights et les logs."
  type        = string
}

variable "multi_az" {
  description = "Déployer une instance de secours synchrone dans une autre AZ."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Nombre de jours de conservation des sauvegardes automatiques (1 à 35)."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period doit être compris entre 1 et 35 (les sauvegardes doivent rester activées)."
  }
}

variable "backup_window" {
  description = "Fenêtre quotidienne de sauvegarde (UTC)."
  type        = string
  default     = "02:00-03:00"
}

variable "maintenance_window" {
  description = "Fenêtre hebdomadaire de maintenance (UTC)."
  type        = string
  default     = "sun:03:30-sun:04:30"
}

variable "apply_immediately" {
  description = "Appliquer les modifications immédiatement plutôt que pendant la fenêtre de maintenance."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Empêcher la suppression de l'instance."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Ne pas prendre de snapshot final à la suppression de l'instance. À laisser à false en production."
  type        = bool
  default     = false
}

variable "cloudwatch_logs_exports" {
  description = "Logs PostgreSQL exportés vers CloudWatch Logs."
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "log_retention_days" {
  description = "Durée de rétention des logs exportés de la base (jours)."
  type        = number
  default     = 30
}

variable "slow_query_threshold_ms" {
  description = "Les requêtes plus lentes que ce seuil sont journalisées (log_min_duration_statement)."
  type        = number
  default     = 1000
}

variable "monitoring_interval" {
  description = "Intervalle de l'Enhanced Monitoring en secondes (0 le désactive)."
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval doit valoir 0, 1, 5, 10, 15, 30 ou 60."
  }
}

variable "performance_insights_enabled" {
  description = "Activer Performance Insights (chiffré avec la CMK)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources."
  type        = map(string)
  default     = {}
}
