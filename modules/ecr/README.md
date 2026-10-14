# Module `ecr`

Registre d'images de l'application.

- Images chiffrées avec la CMK de l'environnement
- **Tags immuables** : un tag publié ne peut pas être écrasé, ce qui garantit des déploiements reproductibles
- **Scan des vulnérabilités** à chaque push
- Lifecycle : images non taguées supprimées après 7 jours, conservation des N dernières images

## Utilisation

```hcl
module "ecr" {
  source = "../../modules/ecr"

  name        = "myapp-prod"
  kms_key_arn = module.kms.key_arn
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
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | ressource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | ressource |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `kms_key_arn` | Clé KMS qui chiffre les images au repos. | `string` | — | oui |
| `name` | Nom du dépôt ECR. | `string` | — | oui |
| `force_delete` | Supprimer le dépôt même s'il contient encore des images. À laisser à false en production. | `bool` | `false` | non |
| `max_image_count` | Nombre d'images conservées dans le dépôt. | `number` | `30` | non |
| `tags` | Tags appliqués au dépôt. | `map(string)` | `{}` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `repository_arn` | ARN du dépôt. |
| `repository_name` | Nom du dépôt. |
| `repository_url` | URL du dépôt (à utiliser pour taguer et pousser les images). |
<!-- END_TF_DOCS -->
