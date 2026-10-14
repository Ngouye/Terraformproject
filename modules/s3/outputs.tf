output "bucket_id" {
  description = "Nom du bucket."
  # `bucket` provient de la configuration : il est connu dès le plan (contrairement
  # à `id`), ce qui permet de l'utiliser dans des conditions count / for_each.
  value = aws_s3_bucket.this.bucket

  # Les producteurs de logs (ALB, journalisation S3) vérifient leurs droits
  # d'écriture à l'activation : la bucket policy doit exister avant.
  depends_on = [aws_s3_bucket_policy.this]
}

output "bucket_arn" {
  description = "ARN du bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Nom de domaine régional du bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
