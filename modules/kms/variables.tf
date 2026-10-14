variable "alias" {
  description = "Alias de la clé, sans le préfixe \"alias/\"."
  type        = string
}

variable "description" {
  description = "Description de la clé KMS."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Délai d'attente avant la suppression effective de la clé (7 à 30 jours)."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days doit être compris entre 7 et 30."
  }
}

variable "tags" {
  description = "Tags appliqués à la clé."
  type        = map(string)
  default     = {}
}
