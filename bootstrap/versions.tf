terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Le state de cette stack reste volontairement local : c'est elle qui crée le
  # backend distant (S3 + DynamoDB) utilisé par toutes les autres stacks. Une fois
  # appliqué, le terraform.tfstate local peut être migré dans le bucket (voir README).
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      Stack     = "bootstrap"
      ManagedBy = "Terraform"
    }
  }
}
