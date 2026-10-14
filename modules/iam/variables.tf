variable "name" {
  description = "Préfixe de nom des rôles IAM."
  type        = string
}

variable "log_group_name" {
  description = "Log group CloudWatch dans lequel écrivent les conteneurs."
  type        = string
}

variable "ecr_repository_arns" {
  description = "Dépôts ECR depuis lesquels le rôle d'exécution peut télécharger les images."
  type        = list(string)
  default     = []
}

variable "secret_arns" {
  description = "Secrets Secrets Manager injectés dans les conteneurs."
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "Clés KMS qui protègent les secrets et les buckets S3."
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "Buckets S3 que l'application peut lire et écrire."
  type        = list(string)
  default     = []
}

variable "enable_execute_command" {
  description = "Accorder les permissions SSM nécessaires à ECS Exec."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags appliqués aux rôles."
  type        = map(string)
  default     = {}
}
