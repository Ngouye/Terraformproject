# Tests unitaires - lancer `terraform test` depuis modules/security-groups.
mock_provider "aws" {}

variables {
  name     = "test"
  vpc_id   = "vpc-0123456789abcdef0"
  app_port = 8080
}

run "tiers_chaines_par_reference_de_security_group" {
  command = apply # simulé : rien n'est créé dans AWS

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_from_alb.referenced_security_group_id == aws_security_group.alb.id
    error_message = "L'application ne doit accepter que le trafic provenant du Security Group de l'ALB."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.db_from_app.referenced_security_group_id == aws_security_group.app.id
    error_message = "La base ne doit accepter que le trafic provenant du Security Group de l'application."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.db_from_app.from_port == 5432 && aws_vpc_security_group_ingress_rule.db_from_app.to_port == 5432
    error_message = "Seul le port PostgreSQL doit être ouvert sur la base."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.alb_to_app.from_port == 8080 && aws_vpc_security_group_egress_rule.alb_to_app.to_port == 8080
    error_message = "L'ALB ne doit joindre que le port applicatif."
  }
}

run "sortie_application_limitee_a_https_et_base" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_egress_rule.app_https.from_port == 443 && aws_vpc_security_group_egress_rule.app_https.ip_protocol == "tcp"
    error_message = "La sortie de l'application vers Internet doit être limitée au HTTPS."
  }
}

run "entree_alb_selon_les_cidr_autorises" {
  command = plan

  variables {
    alb_ingress_cidrs = ["203.0.113.0/24", "198.51.100.10/32"]
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.alb_https) == 2 && contains(keys(aws_vpc_security_group_ingress_rule.alb_https), "198.51.100.10/32")
    error_message = "Une règle HTTPS doit être créée par CIDR autorisé."
  }
}

run "refuse_un_cidr_invalide" {
  command = plan

  variables {
    alb_ingress_cidrs = ["pas-un-cidr"]
  }

  expect_failures = [var.alb_ingress_cidrs]
}
