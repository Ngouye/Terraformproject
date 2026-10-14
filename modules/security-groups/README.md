# Module `security-groups`

Les trois Security Groups de l'application, chaînés **par référence** (aucun CIDR interne) :

```text
CIDR autorisés ──80/443──► ALB ──app_port──► App (ECS) ──5432──► DB (RDS)
                                              └──443──► AWS APIs / registres
```

- Une ressource `aws_vpc_security_group_ingress_rule` / `egress_rule` par règle, chacune décrite
- Le SG de la base n'a aucune règle de sortie (Terraform supprime le *allow all* par défaut d'AWS)
- `name_prefix` + `create_before_destroy` : remplacement sans coupure
- Tests : `terraform test` (4 scénarios, provider mocké)

## Utilisation

```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  name              = "myapp-prod"
  vpc_id            = module.vpc.vpc_id
  app_port          = 8080
  alb_ingress_cidrs = ["0.0.0.0/0"]
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
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | ressource |
| [aws_security_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | ressource |
| [aws_security_group.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | ressource |
| [aws_vpc_security_group_egress_rule.alb_to_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | ressource |
| [aws_vpc_security_group_egress_rule.app_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | ressource |
| [aws_vpc_security_group_egress_rule.app_to_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | ressource |
| [aws_vpc_security_group_ingress_rule.alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | ressource |
| [aws_vpc_security_group_ingress_rule.alb_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | ressource |
| [aws_vpc_security_group_ingress_rule.app_from_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | ressource |
| [aws_vpc_security_group_ingress_rule.db_from_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | ressource |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `app_port` | Port d'écoute du conteneur applicatif. | `number` | — | oui |
| `name` | Préfixe de nom des Security Groups. | `string` | — | oui |
| `vpc_id` | VPC dans lequel les Security Groups sont créés. | `string` | — | oui |
| `alb_ingress_cidrs` | Blocs CIDR IPv4 autorisés à joindre l'ALB (à restreindre aux IP du bureau ou du VPN pour une application interne). | `list(string)` | `["0.0.0.0/0"]` | non |
| `db_port` | Port de la base de données. | `number` | `5432` | non |
| `tags` | Tags appliqués aux Security Groups. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `alb_security_group_id` | Security Group de l'Application Load Balancer. |
| `app_security_group_id` | Security Group des tâches ECS. |
| `db_security_group_id` | Security Group de l'instance RDS. |
<!-- END_TF_DOCS -->
