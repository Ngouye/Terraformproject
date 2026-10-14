output "alb_arn" {
  description = "ARN du load balancer."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "Suffixe de l'ARN du load balancer (dimension CloudWatch)."
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "Nom DNS public du load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID du load balancer (pour les enregistrements alias Route 53)."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN du target group."
  value       = aws_lb_target_group.this.arn

  # ECS refuse d'attacher un service à un target group qui n'est pas encore
  # associé à un load balancer : les consommateurs attendent les listeners.
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}

output "target_group_arn_suffix" {
  description = "Suffixe de l'ARN du target group (dimension CloudWatch)."
  value       = aws_lb_target_group.this.arn_suffix
}

output "https_enabled" {
  description = "Indique si le listener HTTPS est activé."
  value       = local.https_enabled
}
