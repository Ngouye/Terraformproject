variable "name" {
  description = "Préfixe de nom de toutes les ressources du VPC."
  type        = string
}

variable "cidr_block" {
  description = "Bloc CIDR IPv4 du VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block doit être un bloc CIDR IPv4 valide."
  }
}

variable "subnet_newbits" {
  description = "Bits ajoutés au préfixe du VPC pour dimensionner chaque subnet (8 => subnets /24 pour un VPC /16)."
  type        = number
  default     = 8
}

variable "azs" {
  description = "Zones de disponibilité sur lesquelles répartir les subnets (au moins 2, exigé par RDS et l'ALB)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2 && length(var.azs) <= 6
    error_message = "Indiquer entre 2 et 6 zones de disponibilité."
  }
}

variable "single_nat_gateway" {
  description = "Utiliser une seule NAT Gateway partagée (moins cher, hors production) au lieu d'une par AZ (haute disponibilité)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Envoyer les VPC Flow Logs (ACCEPT et REJECT) dans CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Durée de rétention du log group des Flow Logs (jours)."
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "Clé KMS qui chiffre le log group des Flow Logs."
  type        = string
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources."
  type        = map(string)
  default     = {}
}
