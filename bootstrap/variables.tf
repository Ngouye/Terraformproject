variable "aws_region" {
  description = "Région AWS qui héberge le state Terraform distant."
  type        = string
  default     = "eu-west-3"
}

variable "project" {
  description = "Nom du projet, utilisé comme préfixe de toutes les ressources."
  type        = string
  default     = "iac-portfolio"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project))
    error_message = "project doit contenir 3 à 21 caractères (minuscules, chiffres ou tirets) et commencer par une lettre."
  }
}

variable "noncurrent_state_retention_days" {
  description = "Nombre de jours de conservation des anciennes versions des fichiers de state."
  type        = number
  default     = 90
}

variable "github_repository" {
  description = "Dépôt GitHub (\"propriétaire/nom\") autorisé à assumer le rôle CI de plan en lecture seule via OIDC. Laisser vide pour ne pas le créer."
  type        = string
  default     = ""

  validation {
    condition     = var.github_repository == "" || can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository doit être au format \"proprietaire/depot\"."
  }
}
