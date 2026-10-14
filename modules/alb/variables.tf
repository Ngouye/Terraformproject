variable "name" {
  description = "Préfixe de nom des ressources du load balancer (28 caractères maximum)."
  type        = string

  validation {
    condition     = length(var.name) <= 28
    error_message = "name doit faire au plus 28 caractères (les noms d'ALB et de target group sont limités à 32)."
  }
}

variable "vpc_id" {
  description = "VPC du target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets publics dans lesquels l'ALB est déployé (au moins 2 AZ)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group attaché à l'ALB."
  type        = string
}

variable "target_port" {
  description = "Port des cibles (port du conteneur applicatif)."
  type        = number
}

variable "health_check_path" {
  description = "Chemin HTTP utilisé par le health check du target group."
  type        = string
  default     = "/"
}

variable "certificate_arn" {
  description = "ARN du certificat ACM. S'il est défini, un listener HTTPS est créé et HTTP redirige vers HTTPS."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "Politique TLS du listener HTTPS (TLS 1.2 minimum, TLS 1.3 privilégié)."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "access_logs_bucket" {
  description = "Bucket S3 qui reçoit les access logs de l'ALB (doit utiliser SSE-S3). Null désactive les access logs."
  type        = string
  default     = null
}

variable "idle_timeout" {
  description = "Délai d'inactivité des connexions, en secondes."
  type        = number
  default     = 60
}

variable "deletion_protection" {
  description = "Empêcher la suppression de l'ALB."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources."
  type        = map(string)
  default     = {}
}
