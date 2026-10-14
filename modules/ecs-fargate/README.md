# Module `ecs-fargate`

Cluster, task definition et service ECS Fargate derrière un ALB.

- **Task definition durcie** : système de fichiers racine en lecture seule (`/tmp` éphémère inscriptible), `initProcessEnabled`, secrets injectés depuis Secrets Manager
- **Déploiements sûrs** : rolling update 100 % / 200 %, *deployment circuit breaker* avec rollback automatique
- **Auto scaling** par *target tracking* sur le CPU et la mémoire ; `desired_count` ignoré après création (piloté par l'auto scaling)
- Fargate ou **Fargate Spot** (`use_fargate_spot`), x86_64 ou ARM64 (Graviton)
- Container Insights, logs `awslogs` vers un log group chiffré par KMS
- Tâches en subnets privés, sans IP publique

## Utilisation

```hcl
module "ecs" {
  source = "../../modules/ecs-fargate"

  name               = "myapp-prod"
  subnet_ids         = module.vpc.private_app_subnet_ids
  security_group_ids = [module.security_groups.app_security_group_id]
  target_group_arn   = module.alb.target_group_arn
  container_image    = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/myapp-prod:1.0.0"
  container_port     = 8080
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  log_group_name     = "/ecs/myapp-prod/app"
  kms_key_arn        = module.kms.key_arn

  environment = { DB_HOST = module.rds.address }
  secrets     = { DB_PASSWORD = "${module.rds.master_user_secret_arn}:password::" }
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
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | ressource |
| [aws_appautoscaling_policy.memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | ressource |
| [aws_appautoscaling_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | ressource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | ressource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | ressource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | ressource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | ressource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | ressource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | source de données |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `container_image` | Image du conteneur (ex. <compte>.dkr.ecr.<region>.amazonaws.com/<depot>:<tag>). | `string` | — | oui |
| `container_port` | Port d'écoute du conteneur. | `number` | — | oui |
| `execution_role_arn` | Rôle utilisé par l'agent ECS (téléchargement de l'image, logs, secrets). | `string` | — | oui |
| `kms_key_arn` | Clé KMS qui chiffre le log group. | `string` | — | oui |
| `log_group_name` | Nom du log group CloudWatch des conteneurs. | `string` | — | oui |
| `name` | Préfixe de nom des ressources ECS. | `string` | — | oui |
| `security_group_ids` | Security Groups attachés aux tâches. | `list(string)` | — | oui |
| `subnet_ids` | Subnets privés dans lesquels les tâches s'exécutent. | `list(string)` | — | oui |
| `target_group_arn` | Target group de l'ALB dans lequel le service enregistre ses tâches. | `string` | — | oui |
| `task_role_arn` | Rôle assumé par le code applicatif. | `string` | — | oui |
| `container_insights` | Activer CloudWatch Container Insights sur le cluster. | `bool` | `true` | non |
| `container_name` | Nom du conteneur applicatif. | `string` | `"app"` | non |
| `cpu` | Unités CPU de la tâche (256 = 0,25 vCPU). | `number` | `256` | non |
| `cpu_architecture` | Architecture CPU de la tâche : X86_64 ou ARM64 (Graviton, environ 20 % moins cher). | `string` | `"X86_64"` | non |
| `cpu_target_utilization` | Utilisation CPU moyenne (%) visée par l'auto scaling. | `number` | `60` | non |
| `desired_count` | Nombre initial de tâches (ensuite piloté par l'auto scaling). | `number` | `2` | non |
| `enable_execute_command` | Activer ECS Exec (shell interactif dans les conteneurs en cours d'exécution). | `bool` | `false` | non |
| `environment` | Variables d'environnement en clair (ne jamais y mettre de secret). | `map(string)` | `{}` | non |
| `health_check_grace_period_seconds` | Durée pendant laquelle les échecs de health check de l'ALB sont ignorés après le démarrage d'une tâche. | `number` | `60` | non |
| `log_retention_days` | Durée de rétention des logs applicatifs (jours). | `number` | `30` | non |
| `max_capacity` | Nombre maximal de tâches. | `number` | `4` | non |
| `memory` | Mémoire de la tâche en Mio. | `number` | `512` | non |
| `memory_target_utilization` | Utilisation mémoire moyenne (%) visée par l'auto scaling. | `number` | `70` | non |
| `min_capacity` | Nombre minimal de tâches. | `number` | `1` | non |
| `readonly_root_filesystem` | Monter le système de fichiers racine du conteneur en lecture seule (/tmp reste inscriptible). | `bool` | `true` | non |
| `secrets` | Variables d'environnement injectées depuis Secrets Manager / SSM : nom => ARN valueFrom. | `map(string)` | `{}` | non |
| `tags` | Tags appliqués à toutes les ressources. | `map(string)` | `{}` | non |
| `use_fargate_spot` | Exécuter les tâches sur Fargate Spot (jusqu'à 70 % moins cher, interruptions possibles). Recommandé hors production uniquement. | `bool` | `false` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `cluster_arn` | ARN du cluster ECS. |
| `cluster_name` | Nom du cluster ECS. |
| `log_group_name` | Log group CloudWatch des conteneurs. |
| `service_name` | Nom du service ECS. |
| `task_definition_arn` | ARN de la révision courante de la task definition. |
<!-- END_TF_DOCS -->
