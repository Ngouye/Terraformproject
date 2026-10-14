# Module `vpc`

Réseau 3 tiers multi-AZ.

| Tier | Plage (/16 → /24) | Accès Internet |
|---|---|---|
| public | index 0-9 | Internet Gateway (ALB, NAT) |
| private-app | index 10-19 | sortant via NAT |
| private-data | index 20-29 | aucun |

- NAT Gateway unique (`single_nat_gateway = true`, dev) ou une par AZ (prod, haute disponibilité)
- Endpoint S3 de type gateway (gratuit) sur les tiers privés
- VPC Flow Logs (ACCEPT + REJECT) vers CloudWatch Logs chiffré par KMS, rôle IAM protégé contre le *confused deputy*
- Security group par défaut vidé de toutes ses règles (CIS 5.4), aucune IP publique automatique
- Tests : `terraform test` (6 scénarios, provider mocké)

## Utilisation

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name               = "myapp-dev"
  cidr_block         = "10.10.0.0/16"
  azs                = ["eu-west-3a", "eu-west-3b"]
  single_nat_gateway = true
  kms_key_arn        = module.kms.key_arn
}
```

<!-- BEGIN_TF_DOCS -->
## Prérequis

| Nom | Version |
|-----|---------|
| terraform | >= 1.9.0 |
| aws | >= 6.0 |

## Ressources

| Nom | Type |
|-----|------|
| [aws_cloudwatch_log_group.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | ressource |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | ressource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | ressource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | ressource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | ressource |
| [aws_iam_role_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | ressource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | ressource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | ressource |
| [aws_route_table.private_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | ressource |
| [aws_route_table.private_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | ressource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | ressource |
| [aws_route_table_association.private_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | ressource |
| [aws_route_table_association.private_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | ressource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | ressource |
| [aws_subnet.private_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | ressource |
| [aws_subnet.private_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | ressource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | ressource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | ressource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | ressource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | source de données |
| [aws_iam_policy_document.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |
| [aws_iam_policy_document.flow_logs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | source de données |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `azs` | Zones de disponibilité sur lesquelles répartir les subnets (au moins 2, exigé par RDS et l'ALB). | `list(string)` | — | oui |
| `kms_key_arn` | Clé KMS qui chiffre le log group des Flow Logs. | `string` | — | oui |
| `name` | Préfixe de nom de toutes les ressources du VPC. | `string` | — | oui |
| `cidr_block` | Bloc CIDR IPv4 du VPC. | `string` | `"10.0.0.0/16"` | non |
| `enable_flow_logs` | Envoyer les VPC Flow Logs (ACCEPT et REJECT) dans CloudWatch Logs. | `bool` | `true` | non |
| `flow_logs_retention_days` | Durée de rétention du log group des Flow Logs (jours). | `number` | `30` | non |
| `single_nat_gateway` | Utiliser une seule NAT Gateway partagée (moins cher, hors production) au lieu d'une par AZ (haute disponibilité). | `bool` | `false` | non |
| `subnet_newbits` | Bits ajoutés au préfixe du VPC pour dimensionner chaque subnet (8 => subnets /24 pour un VPC /16). | `number` | `8` | non |
| `tags` | Tags appliqués à toutes les ressources. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `flow_logs_log_group_name` | Log group CloudWatch qui reçoit les VPC Flow Logs. |
| `nat_public_ips` | IP publiques des NAT Gateways (IP de sortie de l'application). |
| `private_app_subnet_ids` | Identifiants des subnets privés applicatifs (tâches ECS). |
| `private_data_subnet_ids` | Identifiants des subnets data isolés (RDS). |
| `public_subnet_ids` | Identifiants des subnets publics (ALB, NAT). |
| `vpc_cidr_block` | Bloc CIDR du VPC. |
| `vpc_id` | Identifiant du VPC. |
<!-- END_TF_DOCS -->
