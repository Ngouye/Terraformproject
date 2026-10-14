# Sécurité

Ce document détaille les contrôles de sécurité intégrés au code. Il les relie aux bonnes pratiques
AWS Well-Architected (pilier Sécurité) et CIS AWS Foundations, et justifie chaque exception Checkov.

## Principes

1. **Secure by default** : les valeurs par défaut des modules sont les plus sûres (`deletion_protection = true`,
   chiffrement obligatoire, aucune ouverture réseau implicite). Un environnement doit choisir explicitement d'assouplir.
2. **Moindre privilège** : chaque permission IAM vise un ARN précis. `Resource = "*"` n'apparaît que lorsque l'action
   ne supporte pas de restriction par ressource, et un commentaire l'indique.
3. **Défense en profondeur** : isolation réseau, Security Groups, IAM, chiffrement et journalisation se cumulent.
4. **Aucun secret dans Git ni dans le state.**
5. **Contrôle continu** : chaque PR passe `validate`, `terraform test`, TFLint et Checkov.

## Matrice des contrôles

### Chiffrement at rest

| Ressource | Mécanisme | Clé |
|---|---|---|
| State Terraform (S3) | SSE-KMS + Bucket Key | CMK `bootstrap` dédiée |
| Table de lock DynamoDB | SSE KMS | CMK `bootstrap` |
| RDS : stockage, snapshots, backups | `storage_encrypted` | CMK de l'environnement |
| Secret du mot de passe RDS | `master_user_secret_kms_key_id` | CMK de l'environnement |
| Performance Insights | `performance_insights_kms_key_id` | CMK de l'environnement |
| Bucket assets | SSE-KMS + Bucket Key | CMK de l'environnement |
| Bucket logs | SSE-S3 (AES-256) | gérée par AWS : la livraison des logs ALB n'accepte pas SSE-KMS |
| Images ECR | `encryption_type = KMS` | CMK de l'environnement |
| CloudWatch Logs (app, Flow Logs, RDS) | `kms_key_id` | CMK de l'environnement |
| Topic SNS des alarmes | `kms_master_key_id` | CMK de l'environnement |

Toutes les CMK ont la **rotation automatique** activée et une fenêtre de suppression de 30 jours (7 en dev).
La key policy n'autorise que le compte (délégation à IAM), CloudWatch Logs (conditionné à l'ARN des log groups du compte)
et CloudWatch Alarms (publication des alarmes vers le topic SNS chiffré).

### Chiffrement in transit

| Flux | Contrôle |
|---|---|
| Client → ALB | Listener HTTPS, politique `ELBSecurityPolicy-TLS13-1-2-2021-06`, HTTP redirigé en 301 |
| Application → RDS | `rds.force_ssl = 1` : toute connexion non TLS est refusée |
| Tout accès S3 | Bucket policy `Deny` si `aws:SecureTransport = false` ou TLS < 1.2 |
| ALB | `drop_invalid_header_fields = true`, `desync_mitigation_mode = defensive` |

### Identités et accès (IAM)

| Rôle | Permissions | Restrictions |
|---|---|---|
| ECS execution | `ecr:BatchGetImage`… | dépôt ECR du projet uniquement |
| | `logs:CreateLogStream`, `PutLogEvents` | log group de l'application uniquement |
| | `secretsmanager:GetSecretValue` | secret RDS uniquement |
| | `kms:Decrypt` | CMK, uniquement via Secrets Manager (`kms:ViaService`) |
| ECS task | `s3:ListBucket`, `Get/Put/DeleteObject` | bucket assets uniquement |
| | `kms:Decrypt`, `GenerateDataKey` | CMK, uniquement via S3 (`kms:ViaService`) |
| | `ssmmessages:*` | seulement si ECS Exec est activé (dev) |
| VPC Flow Logs | écriture de logs | log group des Flow Logs uniquement |
| RDS monitoring | policy AWS `AmazonRDSEnhancedMonitoringRole` | service `monitoring.rds.amazonaws.com` |
| CI GitHub (OIDC) | `ReadOnlyAccess` + accès au state | pull requests et branche `main` du dépôt uniquement, audience `sts.amazonaws.com`, sessions d'1 h |

Les rôles assumés par des services AWS ont des conditions **anti confused deputy** (`aws:SourceAccount`, `aws:SourceArn`).
Les rôles execution et task sont **distincts** : l'application n'hérite pas des droits de l'agent ECS.

### Réseau

- Trois tiers de subnets ; le tier data **n'a aucune route** vers Internet ni vers le NAT.
- Security Groups chaînés par **référence** (pas de CIDR interne) : Internet → ALB → App → DB.
- Le SG de la base n'a **aucune règle de sortie**. Le SG applicatif ne sort que vers la base (5432) et en HTTPS (443).
- Le **SG par défaut** du VPC est vidé de toutes ses règles (CIS 5.4).
- Aucune IP publique automatique, base `publicly_accessible = false`, tâches ECS `assign_public_ip = false`.
- Entrée de l'ALB restreignable à des CIDR (`alb_ingress_cidrs`), avec validation du format.

### Secrets

- Le mot de passe maître PostgreSQL est **généré, stocké et renouvelé par RDS** dans Secrets Manager
  (`manage_master_user_password = true`). Il n'apparaît ni dans le code, ni dans les tfvars, ni dans le state.
- Le conteneur le reçoit via le bloc `secrets` de la task definition : l'agent ECS le résout au démarrage.
- L'authentification IAM à la base est activée (`iam_database_authentication_enabled`).
- Les hooks pre-commit `detect-private-key` et `detect-aws-credentials` bloquent les commits de secrets.
- En CI, `persist-credentials: false` : le jeton GitHub n'est pas conservé dans `.git/config` après le checkout.

### Conteneurs et images

- `readonlyRootFilesystem = true` : seul `/tmp` (volume éphémère) est inscriptible.
- Image par défaut **non-root** (`nginx-unprivileged`, port 8080).
- ECR : **scan des vulnérabilités** à chaque push, **tags immuables** (un tag ne peut pas être réécrit), politique de rétention.
- `initProcessEnabled` : gestion propre des signaux et des processus zombies.

### Protection des données

- Versioning S3 et expiration des anciennes versions ; Block Public Access sur les 4 options ; ACL désactivées (`BucketOwnerEnforced`).
- Sauvegardes RDS automatiques (1 à 35 jours, validées), snapshot final en prod, `deletion_protection`.
- `prevent_destroy` sur le bucket de state et la table de lock ; PITR sur la table.
- `deletion_protection` sur l'ALB en prod ; `force_destroy` / `force_delete` désactivés en prod.

### Journalisation et détection

| Source | Destination | Rétention |
|---|---|---|
| Application (stdout/stderr) | CloudWatch Logs (KMS) | 14 j dev / 365 j prod |
| VPC Flow Logs (ALL) | CloudWatch Logs (KMS) | idem |
| PostgreSQL : connexions, déconnexions, DDL, requêtes > 1 s | CloudWatch Logs (KMS) | idem |
| ALB access logs | S3 logs (écriture limitée au chemin `AWSLogs/<compte>/` de ce compte) | idem (lifecycle) |
| Accès au bucket assets | S3 logs | idem |
| 11 alarmes CloudWatch | SNS chiffré → e-mail | — |

## Exceptions Checkov justifiées

| Check | Portée | Justification |
|---|---|---|
| `CKV_AWS_109`, `CKV_AWS_111`, `CKV_AWS_356` | key policies KMS | Dans une key policy, `Resource = "*"` désigne la clé elle-même ; c'est la syntaxe imposée par AWS |
| `CKV_AWS_144` | S3 | Réplication inter-régions hors périmètre (projet mono-région) |
| `CKV_AWS_18` | bucket de state | Traçabilité assurée par CloudTrail data events plutôt que par les access logs S3 |
| `CKV2_AWS_62` | S3 | Pas de notification d'événement nécessaire |
| `CKV2_AWS_28` | ALB | WAF prévu dans la roadmap (service payant) |
| `CKV_AWS_2`, `CKV_AWS_103` | listener HTTP | Le port 80 ne fait qu'une redirection 301 vers HTTPS dès qu'un certificat est fourni (obligatoire en prod) |
| `CKV_AWS_260` | SG ALB port 80 | Idem : le port 80 sert uniquement la redirection |
| `CKV_AWS_338` | log groups | Rétention d'un an appliquée en prod ; 14 jours en dev par choix de coût |
| `CKV2_AWS_5` | SG | Les SG sont attachés via les outputs de modules, que l'analyse module par module ne suit pas |
| `CKV_AWS_224` | cluster ECS | ECS Exec est désactivé en prod |
| `CKV_AWS_378` | target group | Le TLS est terminé sur l'ALB ; le trafic ALB → tâches reste dans les subnets privés, filtré par les SG. TLS de bout en bout : voir la roadmap |
| `CKV_AWS_394` | data source AZ | La liste est tronquée à `az_count` : l'ajout d'une AZ par AWS ne modifie pas les zones utilisées |

Résultat Checkov 3.3 : **326 contrôles réussis, 0 échec**, 18 occurrences d'exceptions justifiées ci-dessus.

## Signaler une vulnérabilité

Merci d'ouvrir une *security advisory* privée sur le dépôt GitHub plutôt qu'une issue publique.
