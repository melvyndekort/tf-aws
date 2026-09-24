# tf-github's read-only PR plan role.
#
# Lives here, not in tf-github, to avoid a circular dependency: if tf-github
# created its own plan role, that role would only exist after a tf-github
# apply, so a PR that broke the plan could not be fixed by a PR, and a fresh
# bootstrap would need tf-github to have already run before tf-github could
# plan. It belongs in the same bootstrap phase that creates the admin
# `github-actions-tf-github` role it mirrors.
#
# The module runs in the management account AND in every subaccount, and the
# role is deliberately different in each:
#
#   management  - assumed directly from GitHub via OIDC on pull_request,
#                 pinned to the shared plan workflow by job_workflow_ref.
#   subaccounts - assumed by the management plan role, because tf-github
#                 manages IAM roles in every account and its plan has to
#                 refresh them cross-account.
#
# Both are read-only. `is_management_account` selects which trust applies.

data "aws_iam_policy_document" "tf_github_plan_assume" {
  # Management: GitHub OIDC, PR runs of the shared plan workflow only.
  dynamic "statement" {
    for_each = var.is_management_account ? [1] : []

    content {
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [aws_iam_openid_connect_provider.github.arn]
      }

      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:aud"
        values   = ["sts.amazonaws.com"]
      }

      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:sub"
        values = [
          "repo:melvyndekort@${var.tf_github_owner_id}/tf-github@${var.tf_github_repo_id}:pull_request",
        ]
      }

      # Without this, any workflow in tf-github could assume the plan role.
      # Pinning job_workflow_ref means only the reviewed, shared plan workflow
      # can - PR-authored workflow code cannot.
      condition {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:job_workflow_ref"
        values   = var.plan_job_workflow_refs
      }
    }
  }

  # Subaccounts: only the management plan role may assume this.
  dynamic "statement" {
    for_each = var.is_management_account ? [] : [1]

    content {
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.management_account_id}:role/external/github-actions-tf-github-plan"]
      }
    }
  }
}

resource "aws_iam_role" "tf_github_plan" {
  name               = "github-actions-tf-github-plan"
  path               = "/external/"
  description        = "Read-only role for terraform plan on pull requests in melvyndekort/tf-github"
  assume_role_policy = data.aws_iam_policy_document.tf_github_plan_assume.json
}

resource "aws_iam_role_policy_attachment" "tf_github_plan_readonly" {
  role       = aws_iam_role.tf_github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# The management plan role must be able to reach the subaccount plan roles,
# since tf-github manages IAM in every account and its plan refreshes them.
data "aws_iam_policy_document" "tf_github_plan_assume_subaccounts" {
  count = var.is_management_account ? 1 : 0

  statement {
    sid       = "AssumeSubaccountPlanRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/external/github-actions-tf-github-plan"]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.organization_id]
    }
  }
}

resource "aws_iam_role_policy" "tf_github_plan_assume_subaccounts" {
  count = var.is_management_account ? 1 : 0

  name   = "assume-subaccount-plan-roles"
  role   = aws_iam_role.tf_github_plan.name
  policy = data.aws_iam_policy_document.tf_github_plan_assume_subaccounts[0].json
}

# tf-github's plan decrypts target=tf-github secrets. ReadOnlyAccess grants
# kms:Describe*/Get*/List* but NOT kms:Decrypt, so the plan fails without this.
# Management-only: the key lives there and only tf-github's own config reads it.
data "aws_iam_policy_document" "tf_github_plan_kms_decrypt" {
  count = var.is_management_account && var.generic_kms_key_arn != "" ? 1 : 0

  statement {
    sid       = "DecryptPlanSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.generic_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "tf_github_plan_kms_decrypt" {
  count = var.is_management_account && var.generic_kms_key_arn != "" ? 1 : 0

  name   = "kms-decrypt"
  role   = aws_iam_role.tf_github_plan.name
  policy = data.aws_iam_policy_document.tf_github_plan_kms_decrypt[0].json
}
