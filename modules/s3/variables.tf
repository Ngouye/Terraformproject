variable "bucket_name" {
  description = "Nom du bucket, unique au niveau mondial."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name doit contenir 3 à 63 caractères : minuscules, chiffres, points ou tirets."
  }
}

variable "kms_key_arn" {
  description = "Clé KMS pour le chiffrement SSE-KMS. Null = SSE-S3 (AES256), obligatoire pour un bucket de logs ALB."
  type        = string
  default     = null
}

variable "versioning_enabled" {
  description = "Activer le versioning des objets."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Nombre de jours après lequel les versions non courantes sont supprimées."
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Nombre de jours après lequel les objets courants expirent (null = jamais). Utile pour les buckets de logs."
  type        = number
  default     = null
}

variable "access_log_bucket" {
  description = "Nom du bucket qui reçoit les access logs S3 de ce bucket (null = désactivé)."
  type        = string
  default     = null
}

variable "attach_elb_log_delivery_policy" {
  description = "Autoriser Elastic Load Balancing à écrire ses access logs dans ce bucket."
  type        = bool
  default     = false
}

variable "attach_access_log_delivery_policy" {
  description = "Autoriser la journalisation d'accès S3 (buckets de ce compte) à écrire dans ce bucket."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Permettre à Terraform de supprimer le bucket même s'il contient des objets. À laisser à false en production."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags appliqués au bucket."
  type        = map(string)
  default     = {}
}
