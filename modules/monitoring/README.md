# Module `monitoring`

Alerting et tableau de bord CloudWatch de l'application.

- **Topic SNS chiffré** par KMS, abonnements e-mail (`alarm_emails`)
- **11 alarmes**, toutes déclarées dans une seule map et créées par un unique bloc `for_each` :
  - ALB : erreurs 5XX (ELB et application), cibles en échec de health check, latence p95
  - ECS : CPU, mémoire, aucune tâche en cours d'exécution
  - RDS : CPU, stockage libre, mémoire disponible, nombre de connexions
- Notification lors du passage en ALARM **et** du retour à OK
- **Dashboard** : trafic et erreurs, latence p50/p95, ECS, RDS, état des alarmes
- Seuils configurables par variables

## Utilisation

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  name                    = "myapp-prod"
  kms_key_arn             = module.kms.key_arn
  alarm_emails            = ["oncall@example.com"]
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  rds_instance_identifier = module.rds.db_instance_identifier
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
| [aws_cloudwatch_dashboard.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | ressource |
| [aws_cloudwatch_metric_alarm.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | ressource |
| [aws_sns_topic.alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | ressource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | ressource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | source de données |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `alb_arn_suffix` | Suffixe de l'ARN de l'ALB. | `string` | — | oui |
| `ecs_cluster_name` | Nom du cluster ECS. | `string` | — | oui |
| `ecs_service_name` | Nom du service ECS. | `string` | — | oui |
| `kms_key_arn` | Clé KMS qui chiffre le topic SNS. | `string` | — | oui |
| `name` | Préfixe de nom des alarmes, du topic et du dashboard. | `string` | — | oui |
| `rds_instance_identifier` | Identifiant de l'instance RDS. | `string` | — | oui |
| `target_group_arn_suffix` | Suffixe de l'ARN du target group. | `string` | — | oui |
| `alarm_emails` | Adresses e-mail notifiées lorsqu'une alarme change d'état. | `list(string)` | `[]` | non |
| `alb_5xx_threshold` | Nombre de réponses 5XX sur 5 minutes qui déclenche une alarme. | `number` | `10` | non |
| `alb_latency_p95_seconds` | Temps de réponse p95 (secondes) qui déclenche une alarme. | `number` | `1.5` | non |
| `ecs_cpu_threshold` | Utilisation CPU du service ECS (%) qui déclenche une alarme. | `number` | `85` | non |
| `ecs_memory_threshold` | Utilisation mémoire du service ECS (%) qui déclenche une alarme. | `number` | `85` | non |
| `rds_connections_threshold` | Nombre de connexions à la base qui déclenche une alarme. | `number` | `80` | non |
| `rds_cpu_threshold` | Utilisation CPU RDS (%) qui déclenche une alarme. | `number` | `80` | non |
| `rds_free_storage_threshold_gb` | Stockage libre RDS (Gio) en dessous duquel une alarme est déclenchée. | `number` | `5` | non |
| `rds_freeable_memory_threshold_mb` | Mémoire disponible RDS (Mio) en dessous de laquelle une alarme est déclenchée. | `number` | `128` | non |
| `tags` | Tags appliqués à toutes les ressources. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `alarm_names` | Noms des alarmes CloudWatch. |
| `dashboard_name` | Nom du dashboard CloudWatch. |
| `dashboard_url` | URL console du dashboard CloudWatch. |
| `sns_topic_arn` | ARN du topic SNS qui reçoit les alarmes. |
<!-- END_TF_DOCS -->
