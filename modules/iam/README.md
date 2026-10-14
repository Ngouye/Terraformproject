# Module `iam`

Rôles IAM au moindre privilège pour un service ECS Fargate.

| Rôle | Utilisé par | Peut faire |
|---|---|---|
| execution | agent ECS | tirer l'image **du dépôt donné**, écrire dans **le log group donné**, lire **les secrets donnés** (déchiffrement KMS via Secrets Manager uniquement) |
| task | code applicatif | lire/écrire **dans les buckets donnés** (KMS via S3 uniquement), ECS Exec si activé |

- Relations de confiance limitées aux tâches ECS du compte et de la région (`aws:SourceAccount`, `aws:SourceArn`)
- Aucune policy managée large (`AmazonECSTaskExecutionRolePolicy` non utilisée)
- Les outputs `*_role_arn` attendent que les policies soient attachées

## Utilisation

```hcl
module "iam" {
  source = "../../modules/iam"

  name                = "myapp-prod"
  log_group_name      = "/ecs/myapp-prod/app"
  ecr_repository_arns = [module.ecr.repository_arn]
  secret_arns         = [module.rds.master_user_secret_arn]
  kms_key_arns        = [module.kms.key_arn]
  s3_bucket_arns      = [module.assets_bucket.bucket_arn]
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
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | ressource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | ressource |
| [aws_iam_role_policy.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | ressource |
| [aws_iam_role_policy.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | ressource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | source de données |
| [aws_iam_policy_document.ecs_tasks_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |
| [aws_iam_policy_document.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |
| [aws_iam_policy_document.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | source de données |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | source de données |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `log_group_name` | Log group CloudWatch dans lequel écrivent les conteneurs. | `string` | — | oui |
| `name` | Préfixe de nom des rôles IAM. | `string` | — | oui |
| `ecr_repository_arns` | Dépôts ECR depuis lesquels le rôle d'exécution peut télécharger les images. | `list(string)` | `[]` | non |
| `enable_execute_command` | Accorder les permissions SSM nécessaires à ECS Exec. | `bool` | `false` | non |
| `kms_key_arns` | Clés KMS qui protègent les secrets et les buckets S3. | `list(string)` | `[]` | non |
| `s3_bucket_arns` | Buckets S3 que l'application peut lire et écrire. | `list(string)` | `[]` | non |
| `secret_arns` | Secrets Secrets Manager injectés dans les conteneurs. | `list(string)` | `[]` | non |
| `tags` | Tags appliqués aux rôles. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `execution_role_arn` | ARN du rôle d'exécution des tâches ECS. |
| `execution_role_name` | Nom du rôle d'exécution des tâches ECS. |
| `task_role_arn` | ARN du rôle de tâche ECS (permissions applicatives). |
| `task_role_name` | Nom du rôle de tâche ECS. |
<!-- END_TF_DOCS -->
