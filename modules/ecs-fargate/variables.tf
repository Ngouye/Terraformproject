variable "name" {
  description = "Préfixe de nom des ressources ECS."
  type        = string
}

################################################################################
# Réseau
################################################################################

variable "subnet_ids" {
  description = "Subnets privés dans lesquels les tâches s'exécutent."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Groups attachés aux tâches."
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group de l'ALB dans lequel le service enregistre ses tâches."
  type        = string
}

################################################################################
# Conteneur
################################################################################

variable "container_name" {
  description = "Nom du conteneur applicatif."
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Image du conteneur (ex. <compte>.dkr.ecr.<region>.amazonaws.com/<depot>:<tag>)."
  type        = string
}

variable "container_port" {
  description = "Port d'écoute du conteneur."
  type        = number
}

variable "environment" {
  description = "Variables d'environnement en clair (ne jamais y mettre de secret)."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Variables d'environnement injectées depuis Secrets Manager / SSM : nom => ARN valueFrom."
  type        = map(string)
  default     = {}
}

variable "readonly_root_filesystem" {
  description = "Monter le système de fichiers racine du conteneur en lecture seule (/tmp reste inscriptible)."
  type        = bool
  default     = true
}

variable "cpu" {
  description = "Unités CPU de la tâche (256 = 0,25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Mémoire de la tâche en Mio."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "Architecture CPU de la tâche : X86_64 ou ARM64 (Graviton, environ 20 % moins cher)."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture doit valoir X86_64 ou ARM64."
  }
}

################################################################################
# IAM
################################################################################

variable "execution_role_arn" {
  description = "Rôle utilisé par l'agent ECS (téléchargement de l'image, logs, secrets)."
  type        = string
}

variable "task_role_arn" {
  description = "Rôle assumé par le code applicatif."
  type        = string
}

################################################################################
# Service
################################################################################

variable "desired_count" {
  description = "Nombre initial de tâches (ensuite piloté par l'auto scaling)."
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Nombre minimal de tâches."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Nombre maximal de tâches."
  type        = number
  default     = 4
}

variable "cpu_target_utilization" {
  description = "Utilisation CPU moyenne (%) visée par l'auto scaling."
  type        = number
  default     = 60
}

variable "memory_target_utilization" {
  description = "Utilisation mémoire moyenne (%) visée par l'auto scaling."
  type        = number
  default     = 70
}

variable "use_fargate_spot" {
  description = "Exécuter les tâches sur Fargate Spot (jusqu'à 70 % moins cher, interruptions possibles). Recommandé hors production uniquement."
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Durée pendant laquelle les échecs de health check de l'ALB sont ignorés après le démarrage d'une tâche."
  type        = number
  default     = 60
}

variable "enable_execute_command" {
  description = "Activer ECS Exec (shell interactif dans les conteneurs en cours d'exécution)."
  type        = bool
  default     = false
}

variable "container_insights" {
  description = "Activer CloudWatch Container Insights sur le cluster."
  type        = bool
  default     = true
}

################################################################################
# Logs
################################################################################

variable "log_group_name" {
  description = "Nom du log group CloudWatch des conteneurs."
  type        = string
}

variable "log_retention_days" {
  description = "Durée de rétention des logs applicatifs (jours)."
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "Clé KMS qui chiffre le log group."
  type        = string
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources."
  type        = map(string)
  default     = {}
}
