# Module `s3`

Bucket S3 sécurisé et réutilisable.

- Chiffrement SSE-KMS avec Bucket Key, ou SSE-S3 si `kms_key_arn = null` (requis pour les access logs ALB)
- Block Public Access (4 options), ACL désactivées (`BucketOwnerEnforced`), versioning
- Bucket policy : refus de HTTP et de TLS < 1.2
- Lifecycle : expiration des versions non courantes, des uploads incomplets, et des objets si `expiration_days` est défini
- Options : réception des access logs ALB (`attach_elb_log_delivery_policy`) et des access logs S3 (`attach_access_log_delivery_policy`), journalisation vers un autre bucket (`access_log_bucket`)

## Utilisation

```hcl
module "assets_bucket" {
  source = "../../modules/s3"

  bucket_name       = "myapp-prod-assets-123456789012"
  kms_key_arn       = module.kms.key_arn
  access_log_bucket = module.logs_bucket.bucket_id
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
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | ressource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | ressource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | ressource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | ressource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | ressource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | ressource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | ressource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | ressource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | source de données |
| [aws_elb_service_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | source de données |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | source de données |

## Entrées

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|:------:|
| `bucket_name` | Nom du bucket, unique au niveau mondial. | `string` | — | oui |
| `access_log_bucket` | Nom du bucket qui reçoit les access logs S3 de ce bucket (null = désactivé). | `string` | `null` | non |
| `attach_access_log_delivery_policy` | Autoriser la journalisation d'accès S3 (buckets de ce compte) à écrire dans ce bucket. | `bool` | `false` | non |
| `attach_elb_log_delivery_policy` | Autoriser Elastic Load Balancing à écrire ses access logs dans ce bucket. | `bool` | `false` | non |
| `expiration_days` | Nombre de jours après lequel les objets courants expirent (null = jamais). Utile pour les buckets de logs. | `number` | `null` | non |
| `force_destroy` | Permettre à Terraform de supprimer le bucket même s'il contient des objets. À laisser à false en production. | `bool` | `false` | non |
| `kms_key_arn` | Clé KMS pour le chiffrement SSE-KMS. Null = SSE-S3 (AES256), obligatoire pour un bucket de logs ALB. | `string` | `null` | non |
| `noncurrent_version_expiration_days` | Nombre de jours après lequel les versions non courantes sont supprimées. | `number` | `90` | non |
| `tags` | Tags appliqués au bucket. | `map(string)` | `{}` | non |
| `versioning_enabled` | Activer le versioning des objets. | `bool` | `true` | non |

## Sorties

| Nom | Description |
|-----|-------------|
| `bucket_arn` | ARN du bucket. |
| `bucket_id` | Nom du bucket. |
| `bucket_regional_domain_name` | Nom de domaine régional du bucket. |
<!-- END_TF_DOCS -->
