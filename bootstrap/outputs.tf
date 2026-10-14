output "state_bucket_name" {
  description = "Nom du bucket S3 qui contient le state Terraform."
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "Nom de la table DynamoDB de verrouillage du state."
  value       = aws_dynamodb_table.locks.name
}

output "state_kms_key_arn" {
  description = "ARN de la clé KMS qui chiffre le state."
  value       = aws_kms_key.state.arn
}

output "backend_config" {
  description = "Contenu à coller dans environments/<env>/backend.hcl."
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.state.id}"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.locks.name}"
    kms_key_id     = "${aws_kms_key.state.arn}"
    encrypt        = true
  EOT
}

output "github_plan_role_arn" {
  description = "ARN du rôle assumé par GitHub Actions pour terraform plan (vide si OIDC est désactivé)."
  value       = local.enable_github_oidc ? aws_iam_role.github_plan[0].arn : ""
}
