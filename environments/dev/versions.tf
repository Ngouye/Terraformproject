terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State distant sur S3, verrouillé par DynamoDB. bucket / region / dynamodb_table /
  # kms_key_id proviennent de backend.hcl :  terraform init -backend-config=backend.hcl
  backend "s3" {
    key     = "dev/terraform.tfstate"
    encrypt = true
  }
}
