data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
}

data "aws_iam_policy_document" "this" {
  #checkov:skip=CKV_AWS_109:Key policy - Resource "*" désigne la clé elle-même
  #checkov:skip=CKV_AWS_111:Key policy - Resource "*" désigne la clé elle-même
  #checkov:skip=CKV_AWS_356:Key policy - Resource "*" désigne la clé elle-même

  # Délègue le contrôle d'accès aux policies IAM du compte (le moindre privilège
  # est appliqué sur chaque rôle, ex. le rôle d'exécution ECS ne peut que kms:Decrypt).
  statement {
    sid       = "EnableIAMPolicies"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
  }

  # CloudWatch Logs a besoin d'une autorisation explicite dans la key policy
  # pour chiffrer les log groups.
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:*"]
    }
  }

  # Les alarmes CloudWatch publient dans un topic SNS chiffré par cette clé
  # (déclaration documentée par AWS pour les actions d'alarme sur un topic chiffré).
  statement {
    sid       = "AllowCloudWatchAlarmsToUseEncryptedSNS"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.this.json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
