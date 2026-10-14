# Tests des garde-fous de la composition de production - lancer `terraform test`
# depuis environments/prod (provider simulé, aucun compte AWS nécessaire).
mock_provider "aws" {
  # Les data sources simulées renvoient des chaînes aléatoires : on leur donne des valeurs réalistes.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com" }
  }

  mock_data "aws_region" {
    defaults = { region = "eu-west-3" }
  }

  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
    }
  }
}

variables {
  certificate_arn = "arn:aws:acm:eu-west-3:123456789012:certificate/11111111-2222-3333-4444-555555555555"
  container_image = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/iac-portfolio-prod:1.0.0"
}

run "plan_production_durci" {
  command = plan

  assert {
    condition     = module.rds.multi_az_enabled
    error_message = "La base de production doit être Multi-AZ."
  }

  assert {
    condition     = module.alb.https_enabled
    error_message = "Le load balancer de production doit servir du HTTPS."
  }

  assert {
    condition     = length(module.vpc.nat_public_ips) == 3
    error_message = "La production doit avoir une NAT Gateway par AZ."
  }
}

run "https_obligatoire" {
  command = plan

  variables {
    certificate_arn = ""
  }

  expect_failures = [var.certificate_arn]
}
