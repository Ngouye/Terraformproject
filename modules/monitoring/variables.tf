variable "name" {
  description = "Préfixe de nom des alarmes, du topic et du dashboard."
  type        = string
}

variable "kms_key_arn" {
  description = "Clé KMS qui chiffre le topic SNS."
  type        = string
}

variable "alarm_emails" {
  description = "Adresses e-mail notifiées lorsqu'une alarme change d'état."
  type        = list(string)
  default     = []
}

################################################################################
# Ressources surveillées
################################################################################

variable "alb_arn_suffix" {
  description = "Suffixe de l'ARN de l'ALB."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Suffixe de l'ARN du target group."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nom du cluster ECS."
  type        = string
}

variable "ecs_service_name" {
  description = "Nom du service ECS."
  type        = string
}

variable "rds_instance_identifier" {
  description = "Identifiant de l'instance RDS."
  type        = string
}

################################################################################
# Seuils
################################################################################

variable "alb_5xx_threshold" {
  description = "Nombre de réponses 5XX sur 5 minutes qui déclenche une alarme."
  type        = number
  default     = 10
}

variable "alb_latency_p95_seconds" {
  description = "Temps de réponse p95 (secondes) qui déclenche une alarme."
  type        = number
  default     = 1.5
}

variable "ecs_cpu_threshold" {
  description = "Utilisation CPU du service ECS (%) qui déclenche une alarme."
  type        = number
  default     = 85
}

variable "ecs_memory_threshold" {
  description = "Utilisation mémoire du service ECS (%) qui déclenche une alarme."
  type        = number
  default     = 85
}

variable "rds_cpu_threshold" {
  description = "Utilisation CPU RDS (%) qui déclenche une alarme."
  type        = number
  default     = 80
}

variable "rds_free_storage_threshold_gb" {
  description = "Stockage libre RDS (Gio) en dessous duquel une alarme est déclenchée."
  type        = number
  default     = 5
}

variable "rds_freeable_memory_threshold_mb" {
  description = "Mémoire disponible RDS (Mio) en dessous de laquelle une alarme est déclenchée."
  type        = number
  default     = 128
}

variable "rds_connections_threshold" {
  description = "Nombre de connexions à la base qui déclenche une alarme."
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources."
  type        = map(string)
  default     = {}
}
