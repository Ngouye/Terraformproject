variable "name" {
  description = "Préfixe de nom des Security Groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC dans lequel les Security Groups sont créés."
  type        = string
}

variable "app_port" {
  description = "Port d'écoute du conteneur applicatif."
  type        = number
}

variable "db_port" {
  description = "Port de la base de données."
  type        = number
  default     = 5432
}

variable "alb_ingress_cidrs" {
  description = "Blocs CIDR IPv4 autorisés à joindre l'ALB (à restreindre aux IP du bureau ou du VPN pour une application interne)."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.alb_ingress_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque entrée de alb_ingress_cidrs doit être un bloc CIDR IPv4 valide."
  }
}

variable "tags" {
  description = "Tags appliqués aux Security Groups."
  type        = map(string)
  default     = {}
}
