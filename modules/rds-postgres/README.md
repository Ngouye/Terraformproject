# Module `rds-postgres`

Instance Amazon RDS for PostgreSQL privée et chiffrée.

- **Chiffrement** du stockage, des snapshots, de Performance Insights et du secret avec la CMK
- **Mot de passe géré par RDS** dans Secrets Manager (`manage_master_user_password`) : jamais dans le code ni dans le state
- **TLS obligatoire** (`rds.force_ssl = 1`), authentification IAM activée, `publicly_accessible = false`
- Parameter group : journalisation des connexions, des déconnexions, du DDL et des requêtes lentes
- Log groups CloudWatch créés à l'avance (rétention et chiffrement maîtrisés)
- Stockage gp3 avec autoscaling, Multi-AZ optionnel, sauvegardes 1 à 35 jours (validées), snapshot final, Enhanced Monitoring

## Utilisation

```hcl
module "rds" {
  source = "../../modules/rds-postgres"

  identifier         = "myapp-prod-postgres"
  instance_class     = "db.t4g.medium"
  multi_az           = true
  subnet_ids         = module.vpc.private_data_subnet_ids
  security_group_ids = [module.security_groups.db_security_group_id]
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
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | ressource |
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | ressource |
| [aws_db_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | ressource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | ressource |
| [aws_iam_role.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | ressource |
| [aws_iam_role_policy_attachment.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | ressource |
| [aws_iam_policy_document.monitoring_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | source de données |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `identifier` | Identifiant de l'instance RDS. | `string` | — | oui |
| `kms_key_arn` | Clé KMS qui chiffre le stockage, les snapshots, le secret maître, Performance Insights et les logs. | `string` | — | oui |
| `security_group_ids` | Security Groups attachés à l'instance. | `list(string)` | — | oui |
| `subnet_ids` | Subnets isolés du DB subnet group (au moins 2 AZ). | `list(string)` | — | oui |
| `allocated_storage` | Stockage initial en Gio. | `number` | `20` | non |
| `apply_immediately` | Appliquer les modifications immédiatement plutôt que pendant la fenêtre de maintenance. | `bool` | `false` | non |
| `backup_retention_period` | Nombre de jours de conservation des sauvegardes automatiques (1 à 35). | `number` | `7` | non |
| `backup_window` | Fenêtre quotidienne de sauvegarde (UTC). | `string` | `"02:00-03:00"` | non |
| `cloudwatch_logs_exports` | Logs PostgreSQL exportés vers CloudWatch Logs. | `list(string)` | `["postgresql", "upgrade"]` | non |
| `db_name` | Nom de la base créée au lancement. | `string` | `"app"` | non |
| `deletion_protection` | Empêcher la suppression de l'instance. | `bool` | `true` | non |
| `engine_version` | Version de PostgreSQL. Une version majeure (ex. "17") laisse RDS appliquer automatiquement les mises à jour mineures. | `string` | `"17"` | non |
| `instance_class` | Classe d'instance (ex. db.t4g.micro en dev, db.m7g.large en prod). | `string` | `"db.t4g.micro"` | non |
| `log_retention_days` | Durée de rétention des logs exportés de la base (jours). | `number` | `30` | non |
| `maintenance_window` | Fenêtre hebdomadaire de maintenance (UTC). | `string` | `"sun:03:30-sun:04:30"` | non |
| `master_username` | Nom de l'utilisateur maître (le mot de passe est géré par RDS dans Secrets Manager). | `string` | `"app_admin"` | non |
| `max_allocated_storage` | Limite haute de l'autoscaling du stockage en Gio. | `number` | `100` | non |
| `monitoring_interval` | Intervalle de l'Enhanced Monitoring en secondes (0 le désactive). | `number` | `60` | non |
| `multi_az` | Déployer une instance de secours synchrone dans une autre AZ. | `bool` | `false` | non |
| `parameter_group_family` | Famille du parameter group, correspondant à engine_version. | `string` | `"postgres17"` | non |
| `performance_insights_enabled` | Activer Performance Insights (chiffré avec la CMK). | `bool` | `false` | non |
| `port` | Port de la base de données. | `number` | `5432` | non |
| `skip_final_snapshot` | Ne pas prendre de snapshot final à la suppression de l'instance. À laisser à false en production. | `bool` | `false` | non |
| `slow_query_threshold_ms` | Les requêtes plus lentes que ce seuil sont journalisées (log_min_duration_statement). | `number` | `1000` | non |
| `tags` | Tags appliqués à toutes les ressources. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `address` | Nom d'hôte de l'instance. |
| `db_instance_arn` | ARN de l'instance. |
| `db_instance_identifier` | Identifiant de l'instance (dimension CloudWatch). |
| `db_name` | Nom de la base de données. |
| `master_user_secret_arn` | ARN du secret Secrets Manager qui contient les identifiants maîtres. |
| `master_username` | Nom de l'utilisateur maître. |
| `multi_az_enabled` | Indique si une instance de secours Multi-AZ est déployée. |
| `port` | Port de l'instance. |
<!-- END_TF_DOCS -->
