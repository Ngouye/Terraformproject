output "vpc_id" {
  description = "Identifiant du VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "Bloc CIDR du VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Identifiants des subnets publics (ALB, NAT)."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Identifiants des subnets privés applicatifs (tâches ECS)."
  value       = aws_subnet.private_app[*].id

  # Les tâches téléchargent leur image via la NAT Gateway : attendre les routes.
  depends_on = [aws_route_table_association.private_app]
}

output "private_data_subnet_ids" {
  description = "Identifiants des subnets data isolés (RDS)."
  value       = aws_subnet.private_data[*].id
}

output "nat_public_ips" {
  description = "IP publiques des NAT Gateways (IP de sortie de l'application)."
  value       = aws_eip.nat[*].public_ip
}

output "flow_logs_log_group_name" {
  description = "Log group CloudWatch qui reçoit les VPC Flow Logs."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
