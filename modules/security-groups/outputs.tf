output "alb_security_group_id" {
  description = "Security Group de l'Application Load Balancer."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security Group des tâches ECS."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security Group de l'instance RDS."
  value       = aws_security_group.db.id
}
