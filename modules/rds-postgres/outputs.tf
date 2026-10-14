output "db_instance_identifier" {
  description = "Identifiant de l'instance (dimension CloudWatch)."
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "ARN de l'instance."
  value       = aws_db_instance.this.arn
}

output "address" {
  description = "Nom d'hôte de l'instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port de l'instance."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nom de la base de données."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Nom de l'utilisateur maître."
  value       = aws_db_instance.this.username
}

output "multi_az_enabled" {
  description = "Indique si une instance de secours Multi-AZ est déployée."
  value       = aws_db_instance.this.multi_az
}

output "master_user_secret_arn" {
  description = "ARN du secret Secrets Manager qui contient les identifiants maîtres."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
