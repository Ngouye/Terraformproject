################################################################################
# Rôles IAM au moindre privilège pour un service ECS Fargate.
#
# - Rôle d'exécution : utilisé par l'agent ECS pour télécharger l'image, écrire
#   les logs et injecter les secrets. Limité au dépôt, au log group et aux
#   secrets exacts.
# - Rôle de tâche : utilisé par le code applicatif. Limité aux buckets S3 exacts.
################################################################################

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  partition     = data.aws_partition.current.partition
  region        = data.aws_region.current.region
  log_group_arn = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${var.log_group_name}"

  task_policy_required = length(var.s3_bucket_arns) > 0 || var.enable_execute_command
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # Protection « confused deputy » : uniquement les tâches ECS de ce compte et de cette région.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${local.partition}:ecs:${local.region}:${local.account_id}:*"]
    }
  }
}

################################################################################
# Rôle d'exécution
################################################################################

resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-execution"
  description        = "Agent ECS : téléchargement de l'image, écriture des logs, lecture des secrets de ${var.name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "ECRAuthentication"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # cette action ne supporte pas de restriction par ressource
  }

  dynamic "statement" {
    for_each = length(var.ecr_repository_arns) > 0 ? [1] : []

    content {
      sid = "PullImagesFromProjectRepositories"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
      ]
      resources = var.ecr_repository_arns
    }
  }

  statement {
    sid       = "WriteApplicationLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.log_group_arn}:*"]
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid       = "ReadInjectedSecrets"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 && length(var.kms_key_arns) > 0 ? [1] : []

    content {
      sid       = "DecryptSecrets"
      actions   = ["kms:Decrypt"]
      resources = var.kms_key_arns

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["secretsmanager.${local.region}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "ecs-execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

################################################################################
# Rôle de tâche
################################################################################

resource "aws_iam_role" "task" {
  name               = "${var.name}-ecs-task"
  description        = "Permissions applicatives de ${var.name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "task" {
  count = local.task_policy_required ? 1 : 0

  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "ListApplicationBuckets"
      actions   = ["s3:ListBucket"]
      resources = var.s3_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "ReadWriteApplicationObjects"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = [for arn in var.s3_bucket_arns : "${arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 && length(var.kms_key_arns) > 0 ? [1] : []

    content {
      sid       = "UseBucketEncryptionKey"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = var.kms_key_arns

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${local.region}.amazonaws.com"]
      }
    }
  }

  # ECS Exec (shell interactif de débogage) s'appuie sur SSM Session Manager.
  dynamic "statement" {
    for_each = var.enable_execute_command ? [1] : []

    content {
      sid = "EcsExecSessionManager"
      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]
      resources = ["*"] # ces actions ne supportent pas de restriction par ressource
    }
  }
}

resource "aws_iam_role_policy" "task" {
  count = local.task_policy_required ? 1 : 0

  name   = "application"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task[0].json
}
