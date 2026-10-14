variable "name" {
  description = "Nom du dépôt ECR."
  type        = string
}

variable "kms_key_arn" {
  description = "Clé KMS qui chiffre les images au repos."
  type        = string
}

variable "max_image_count" {
  description = "Nombre d'images conservées dans le dépôt."
  type        = number
  default     = 30
}

variable "force_delete" {
  description = "Supprimer le dépôt même s'il contient encore des images. À laisser à false en production."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags appliqués au dépôt."
  type        = map(string)
  default     = {}
}
