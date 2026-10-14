output "key_arn" {
  description = "ARN de la clé KMS."
  value       = aws_kms_key.this.arn
}

output "key_id" {
  description = "Identifiant de la clé KMS."
  value       = aws_kms_key.this.key_id
}

output "alias_name" {
  description = "Alias de la clé KMS."
  value       = aws_kms_alias.this.name
}
