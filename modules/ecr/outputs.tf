output "repository_url" {
  description = "URL du dépôt (à utiliser pour taguer et pousser les images)."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN du dépôt."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Nom du dépôt."
  value       = aws_ecr_repository.this.name
}
