################################################################################
# Optionnel : rôle OIDC GitHub Actions utilisé par la CI pour `terraform plan`.
# Aucune clé AWS longue durée n'est stockée dans GitHub. Le rôle est en lecture
# seule sur l'infrastructure et n'a que le strict nécessaire sur le backend.
################################################################################

locals {
  enable_github_oidc = var.github_repository != ""
}

resource "aws_iam_openid_connect_provider" "github" {
  count = local.enable_github_oidc ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_assume" {
  count = local.enable_github_oidc ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Seuls les pull requests et la branche main du dépôt indiqué peuvent
    # assumer le rôle (pas les autres branches).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository}:pull_request",
        "repo:${var.github_repository}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_plan" {
  count = local.enable_github_oidc ? 1 : 0

  name                 = "${var.project}-github-plan"
  description          = "Assumé par GitHub Actions (${var.github_repository}) pour exécuter terraform plan"
  assume_role_policy   = data.aws_iam_policy_document.github_assume[0].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "github_plan_readonly" {
  count = local.enable_github_oidc ? 1 : 0

  role       = aws_iam_role.github_plan[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "github_plan_state" {
  count = local.enable_github_oidc ? 1 : 0

  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "ReadStateObjects"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  statement {
    sid       = "AcquireStateLock"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
    resources = [aws_dynamodb_table.locks.arn]
  }

  statement {
    sid       = "UseStateKey"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [aws_kms_key.state.arn]
  }
}

resource "aws_iam_role_policy" "github_plan_state" {
  count = local.enable_github_oidc ? 1 : 0

  name   = "terraform-state-access"
  role   = aws_iam_role.github_plan[0].id
  policy = data.aws_iam_policy_document.github_plan_state[0].json
}
