data "aws_caller_identity" "current" {}

# Compte ELB historique de la région (régions ouvertes avant août 2022).
data "aws_elb_service_account" "this" {
  count = var.attach_elb_log_delivery_policy ? 1 : 0
}

locals {
  sse_algorithm = var.kms_key_arn == null ? "AES256" : "aws:kms"

  # Le service ELB est partagé par tous les comptes AWS de la région : on limite
  # l'écriture aux logs de CE compte (chemin <préfixe>/AWSLogs/<compte>/...), pour
  # qu'un ALB d'un autre compte ne puisse pas déposer ses logs dans ce bucket.
  elb_log_objects_arn = "${aws_s3_bucket.this.arn}/*AWSLogs/${data.aws_caller_identity.current.account_id}/*"
}

resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_144:Réplication inter-régions non requise pour ce projet
  #checkov:skip=CKV2_AWS_62:Notifications d'événements non nécessaires
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.sse_algorithm
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "default"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    dynamic "expiration" {
      for_each = var.expiration_days == null ? [] : [var.expiration_days]

      content {
        days = expiration.value
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_logging" "this" {
  count = var.access_log_bucket == null ? 0 : 1

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_log_bucket
  target_prefix = "s3-access/${var.bucket_name}/"
}

################################################################################
# Bucket policy : TLS obligatoire + autorisations optionnelles de dépôt de logs
################################################################################

data "aws_iam_policy_document" "this" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "DenyOutdatedTLS"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }

  dynamic "statement" {
    for_each = var.attach_elb_log_delivery_policy ? [1] : []

    content {
      sid       = "AllowELBLogDeliveryLegacyAccount"
      actions   = ["s3:PutObject"]
      resources = [local.elb_log_objects_arn]

      principals {
        type        = "AWS"
        identifiers = [data.aws_elb_service_account.this[0].arn]
      }
    }
  }

  dynamic "statement" {
    for_each = var.attach_elb_log_delivery_policy ? [1] : []

    content {
      sid       = "AllowELBLogDeliveryService"
      actions   = ["s3:PutObject"]
      resources = [local.elb_log_objects_arn]

      principals {
        type        = "Service"
        identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.attach_access_log_delivery_policy ? [1] : []

    content {
      sid       = "AllowS3ServerAccessLogDelivery"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this.arn}/s3-access/*"]

      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
