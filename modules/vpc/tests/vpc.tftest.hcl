# Tests unitaires - lancer `terraform test` depuis modules/vpc (aucun compte AWS nécessaire).
mock_provider "aws" {
  # Les data sources simulées renvoient des chaînes aléatoires : on fournit un JSON valide aux policy documents.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name        = "test"
  cidr_block  = "10.0.0.0/16"
  azs         = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
  kms_key_arn = "arn:aws:kms:eu-west-3:123456789012:key/11111111-2222-3333-4444-555555555555"
}

run "un_subnet_par_tier_et_par_az" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private_app) == 3 && length(aws_subnet.private_data) == 3
    error_message = "Chaque tier doit avoir exactement un subnet par zone de disponibilité."
  }

  assert {
    condition = (
      aws_subnet.public[0].cidr_block == "10.0.0.0/24" &&
      aws_subnet.private_app[0].cidr_block == "10.0.10.0/24" &&
      aws_subnet.private_data[2].cidr_block == "10.0.22.0/24"
    )
    error_message = "Les CIDR doivent suivre le plan d'adressage public 0-9 / app 10-19 / data 20-29."
  }
}

run "aucune_ip_publique_automatique" {
  command = plan

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Les subnets publics ne doivent pas attribuer d'IP publique automatiquement."
  }
}

run "une_nat_par_az_par_defaut" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Par défaut (production), il doit y avoir une NAT Gateway par AZ."
  }
}

run "option_nat_unique" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway doit créer exactement une NAT Gateway."
  }
}

run "flow_logs_actifs_et_chiffres" {
  command = plan

  assert {
    condition     = length(aws_flow_log.this) == 1 && aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Les VPC Flow Logs doivent capturer le trafic accepté et rejeté."
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].kms_key_id == var.kms_key_arn
    error_message = "Le log group des Flow Logs doit être chiffré avec la clé KMS fournie."
  }
}

run "refuse_une_seule_az" {
  command = plan

  variables {
    azs = ["eu-west-3a"]
  }

  expect_failures = [var.azs]
}
