# Module `alb`

Application Load Balancer public devant le service ECS.

- Avec `certificate_arn` : listener HTTPS (politique TLS 1.3 / 1.2) et redirection 301 de HTTP vers HTTPS
- Sans certificat (dev) : HTTP transmis directement au target group
- Target group de type `ip` (requis par Fargate) avec health check configurable
- `drop_invalid_header_fields`, mitigation de *desync*, access logs vers S3, protection contre la suppression
- L'output `target_group_arn` n'est disponible qu'une fois les listeners créés (évite l'erreur ECS *target group does not have an associated load balancer*)

## Utilisation

```hcl
module "alb" {
  source = "../../modules/alb"

  name               = "myapp-prod"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_id  = module.security_groups.alb_security_group_id
  target_port        = 8080
  certificate_arn    = "arn:aws:acm:eu-west-3:123456789012:certificate/..."
  access_logs_bucket = module.logs_bucket.bucket_id
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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | ressource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | ressource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | ressource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | ressource |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `name` | Préfixe de nom des ressources du load balancer (28 caractères maximum). | `string` | — | oui |
| `public_subnet_ids` | Subnets publics dans lesquels l'ALB est déployé (au moins 2 AZ). | `list(string)` | — | oui |
| `security_group_id` | Security Group attaché à l'ALB. | `string` | — | oui |
| `target_port` | Port des cibles (port du conteneur applicatif). | `number` | — | oui |
| `vpc_id` | VPC du target group. | `string` | — | oui |
| `access_logs_bucket` | Bucket S3 qui reçoit les access logs de l'ALB (doit utiliser SSE-S3). Null désactive les access logs. | `string` | `null` | non |
| `certificate_arn` | ARN du certificat ACM. S'il est défini, un listener HTTPS est créé et HTTP redirige vers HTTPS. | `string` | `null` | non |
| `deletion_protection` | Empêcher la suppression de l'ALB. | `bool` | `true` | non |
| `health_check_path` | Chemin HTTP utilisé par le health check du target group. | `string` | `"/"` | non |
| `idle_timeout` | Délai d'inactivité des connexions, en secondes. | `number` | `60` | non |
| `ssl_policy` | Politique TLS du listener HTTPS (TLS 1.2 minimum, TLS 1.3 privilégié). | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | non |
| `tags` | Tags appliqués à toutes les ressources. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `alb_arn` | ARN du load balancer. |
| `alb_arn_suffix` | Suffixe de l'ARN du load balancer (dimension CloudWatch). |
| `alb_dns_name` | Nom DNS public du load balancer. |
| `alb_zone_id` | Hosted zone ID du load balancer (pour les enregistrements alias Route 53). |
| `https_enabled` | Indique si le listener HTTPS est activé. |
| `target_group_arn` | ARN du target group. |
| `target_group_arn_suffix` | Suffixe de l'ARN du target group (dimension CloudWatch). |
<!-- END_TF_DOCS -->
