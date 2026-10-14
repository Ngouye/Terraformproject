provider "aws" {
  region = var.aws_region

  # Appliqués à toutes les ressources taguables : suivi des coûts et responsabilité.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  }
}
