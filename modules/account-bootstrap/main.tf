# GitHub OIDC Provider
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/jwks"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# tf-github Role
data "aws_iam_policy_document" "tf_github_assume" {
  statement {
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
        # Immutable-subject format (embeds owner_id/repo_id), GitHub's
        # current default for newly created repos.
        #
        # F1 resolution (tf-github-redesign-plan-2026-10.md §8 Phase 2
        # task 7, §5.1 exit criterion): the `:ref:refs/heads/main`
        # fallback subject is removed now that the transition is
        # complete. Verified before removing it: tf-github's only apply-
        # role caller is .github/workflows/terraform-apply.yml, which
        # calls the shared melvyndekort/gha-workflows terraform-apply.yml@v1
        # with `environment: production` (the reusable workflow sets
        # `environment: ${{ inputs.environment }}` on its job) - that
        # produces the `:environment:production` subject, never
        # `:ref:refs/heads/main`. No other workflow in tf-github assumes
        # this role (terraform-pr.yml uses the separate, read-only plan
        # role instead). The Phase 1 EventBridge rule monitoring for the
        # ref-based subject (tf-github-ref-based-assume-notifications,
        # management/notifications-monitoring.tf) never fired.
        "repo:melvyndekort@${var.tf_github_owner_id}/tf-github@${var.tf_github_repo_id}:environment:production",
      ]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:role/external/github-actions-tf-github"]
    }
  }
}

resource "aws_iam_role" "tf_github" {
  name                 = "github-actions-tf-github"
  path                 = "/external/"
  assume_role_policy   = data.aws_iam_policy_document.tf_github_assume.json
  permissions_boundary = aws_iam_policy.terraform_github_boundary.arn
}

resource "aws_iam_role_policy_attachment" "tf_github_admin" {
  role       = aws_iam_role.tf_github.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# F2 remediation (tf-github-redesign-plan-2026-10.md §4.6, §5.1): bounds what
# github-actions-tf-github can do despite holding AdministratorAccess. Denies
# long-lived credential creation outright and restricts iam:PassRole to the
# /external/ OIDC-role path (plus Terraform's own usage), so a compromised or
# buggy tf-github apply cannot mint IAM users/keys or pass an unrelated role to
# a service. Everything else a Terraform apply needs stays allowed.
data "aws_iam_policy_document" "terraform_github_boundary" {
  statement {
    sid    = "DenyLongLivedCredentialCreation"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:AttachUserPolicy",
      "iam:PutUserPolicy",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyPassRoleOutsideExternalPath"
    effect    = "Deny"
    actions   = ["iam:PassRole"]
    resources = ["*"]

    condition {
      test     = "StringNotLike"
      variable = "iam:PassedToService"
      values   = ["terraform*"]
    }

    condition {
      test     = "StringNotLike"
      variable = "iam:RoleName"
      values   = ["/external/*"]
    }
  }

  statement {
    sid       = "AllowEverythingElse"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_github_boundary" {
  name        = "TerraformGitHubBoundary"
  description = "Permissions boundary for github-actions-tf-github: denies long-lived credential creation and PassRole outside /external/"
  policy      = data.aws_iam_policy_document.terraform_github_boundary.json
}

# tf-github Plan Role (read-only counterpart of the role above, for PR runs)
#
# Lives here rather than in tf-github to avoid a circular dependency: a plan
# role created by tf-github would only exist after a tf-github apply, so a PR
# that broke the plan could not be fixed by a PR.
data "aws_iam_policy_document" "tf_github_plan_assume" {
  statement {
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
        # Same immutable-subject format as the apply role, but :pull_request
        # instead of a branch ref - that mismatch is why PR runs used to fail.
        "repo:melvyndekort@${var.tf_github_owner_id}/tf-github@${var.tf_github_repo_id}:pull_request",
      ]
    }
    condition {
      # The apply role needs no equivalent: it is reachable only from main,
      # which is already review-gated. A PR can contain arbitrary workflow
      # code, so this pins the role to the reviewed shared plan workflow.
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = var.plan_job_workflow_refs
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      # Account root narrowed by condition, not the role ARN directly.
      #
      # In the management account this statement's target IS this very role, and
      # IAM rejects a principal ARN it cannot resolve at CreateRole time
      # (MalformedPolicyDocument). The apply role above survives the direct form
      # only because it predates its own self-referencing statement; a role
      # created from scratch has no such history.
      #
      # Same idiom AdminRole already uses for the github-actions-* roles below:
      # the root always exists, and the PrincipalArn condition keeps it exactly
      # as narrow as naming the role.
      identifiers = ["arn:aws:iam::${var.management_account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${var.management_account_id}:role/external/github-actions-tf-github-plan"]
    }
  }
}

resource "aws_iam_role" "tf_github_plan" {
  name               = "github-actions-tf-github-plan"
  path               = "/external/"
  assume_role_policy = data.aws_iam_policy_document.tf_github_plan_assume.json
  # F7 (tf-github-redesign-plan-2026-10.md §5.3, §8 Phase 1 task 7) asked for
  # MaxSessionDuration=900 here, but IAM rejects any value below 3600 on this
  # attribute (confirmed: "expected max_session_duration to be in the range
  # (3600 - 43200), got 900") - it is not configurable down to 900. The real
  # enforcement point is the `role-duration-seconds: 900` already specified on
  # the plan workflow's configure-aws-credentials step (plan §7.2), which caps
  # the actual token lifetime for this role regardless of the role's own
  # (unavoidable 3600s minimum) ceiling. No Terraform change needed for F7.
}

resource "aws_iam_role_policy_attachment" "tf_github_plan_readonly" {
  role       = aws_iam_role.tf_github_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Admin Role with unified trust policy
data "aws_iam_policy_document" "admin_assume" {
  # Local user with MFA (works in root, harmless in subaccounts)
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.melvyn_user_arn]
    }

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }

  # YubikeyRole from management account (works everywhere)
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession", "sts:SetSourceIdentity"]

    principals {
      type        = "AWS"
      identifiers = [var.yubikey_role_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.organization_id]
    }
  }

  # tf-github's own apply role, from the management account (for cross-account
  # access while it provisions other repos' OIDC roles in this account).
  #
  # F5 remediation (tf-github-redesign-plan-2026-10.md §4.7, §5.1): this used
  # to be a StringLike wildcard "role/github-actions-*", intended to trust only
  # tf-github's bootstrap role but in practice matching the name prefix of
  # EVERY per-repo apply role tf-github creates (github-actions-<repo>) too,
  # in the management account. Confirmed via CloudTrail (zero
  # AssumeRole-on-AdminRole events in any account, 90-day lookback) that
  # nothing currently depends on that reach, and the wildcard never actually
  # matched the real path-qualified ARN anyway (every github-actions-* role is
  # created at path /external/, so its ARN is .../role/external/github-actions-*
  # - the old pattern omitted the path segment and could not have matched).
  # Narrowed to the exact ARN of github-actions-tf-github only.
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession", "sts:SetSourceIdentity"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.organization_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${var.management_account_id}:role/external/github-actions-tf-github"]
    }
  }
}

resource "aws_iam_role" "admin" {
  name               = "AdminRole"
  assume_role_policy = data.aws_iam_policy_document.admin_assume.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Generic read-only role. Trust is deliberately narrow (see variable
# description below) even though the role itself carries no org-specific
# logic - any principal added to the trust list gets the same ReadOnlyAccess.
data "aws_iam_policy_document" "readonly_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.readonly_role_trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "readonly" {
  name               = "ReadOnlyRole"
  description        = "Read-only cross-account access, trusted by the principals in readonly_role_trusted_principal_arns"
  assume_role_policy = data.aws_iam_policy_document.readonly_assume.json
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Purpose-specific role for read-only Terraform plans (e.g. the weekly drift
# check). Kept separate from the generic ReadOnlyRole above so that decrypt
# grants never attach to a role other consumers may be trusted on. The module
# creates it everywhere with plain ReadOnlyAccess; accounts whose plans must
# decrypt secrets add a target-scoped kms:Decrypt at the call site, the same
# way AdminRole gets its per-account extras. Trusted directly, no role chaining.
data "aws_iam_policy_document" "terraform_plan_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.terraform_plan_role_trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "terraform_plan" {
  name               = "TerraformPlanRole"
  description        = "Read-only Terraform plan access, trusted by the principals in terraform_plan_role_trusted_principal_arns"
  assume_role_policy = data.aws_iam_policy_document.terraform_plan_assume.json
}

resource "aws_iam_role_policy_attachment" "terraform_plan" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Terraform state bucket
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tfstate" {
  bucket = "mdekort-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate_org_read" {
  bucket = aws_s3_bucket.tfstate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowOrgRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.tfstate.arn}/*"
      Condition = {
        StringEquals = {
          "aws:PrincipalOrgID" = var.organization_id
        }
      }
    }]
  })
}
