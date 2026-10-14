# Module `kms`

Clé KMS gérée par le client (CMK) qui chiffre toutes les données au repos d'un environnement :
RDS, secrets, S3, ECR, CloudWatch Logs et SNS.

- Rotation automatique annuelle activée
- Key policy minimale : délégation à IAM du compte, CloudWatch Logs limité aux log groups du compte, CloudWatch Alarms (publication vers le topic SNS chiffré)
- Fenêtre de suppression configurable (7 à 30 jours, validée)

## Utilisation

```hcl
module "kms" {
  source = "../../modules/kms"

  alias       = "myapp-prod"
  description = "myapp-prod - encryption at rest"
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
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | ressource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | ressource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | source de données |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | source de données |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | source de données |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `alias` | Alias de la clé, sans le préfixe "alias/". | `string` | — | oui |
| `description` | Description de la clé KMS. | `string` | — | oui |
| `deletion_window_in_days` | Délai d'attente avant la suppression effective de la clé (7 à 30 jours). | `number` | `30` | non |
| `tags` | Tags appliqués à la clé. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `alias_name` | Alias de la clé KMS. |
| `key_arn` | ARN de la clé KMS. |
| `key_id` | Identifiant de la clé KMS. |
<!-- END_TF_DOCS -->
