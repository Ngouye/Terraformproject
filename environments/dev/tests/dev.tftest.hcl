# Tests de la composition de développement - lancer `terraform test`
# depuis environments/dev (provider simulé, aucun compte AWS nécessaire).
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

run "plan_dev_optimise_en_couts" {
  command = plan

  assert {
    condition     = length(module.vpc.nat_public_ips) == 1
    error_message = "Le développement doit partager une seule NAT Gateway."
  }

  assert {
    condition     = !module.rds.multi_az_enabled
    error_message = "La base de développement doit être mono-AZ."
  }

  assert {
    condition     = !module.alb.https_enabled && startswith(output.app_url, "http://")
    error_message = "Sans certificat, le développement doit servir du HTTP simple."
  }
}

run "dev_avec_https" {
  command = plan

  variables {
    certificate_arn = "arn:aws:acm:eu-west-3:123456789012:certificate/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition     = module.alb.https_enabled && startswith(output.app_url, "https://")
    error_message = "Fournir un certificat doit activer le HTTPS."
  }
}

run "refuse_un_environnement_inconnu" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}
