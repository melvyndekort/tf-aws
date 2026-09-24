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
        "repo:melvyndekort@${var.tf_github_owner_id}/tf-github@${var.tf_github_repo_id}:ref:refs/heads/main",
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
  name               = "github-actions-tf-github"
  path               = "/external/"
  assume_role_policy = data.aws_iam_policy_document.tf_github_assume.json
}

resource "aws_iam_role_policy_attachment" "tf_github_admin" {
  role       = aws_iam_role.tf_github.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
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

  # GitHub Actions roles from management account (for cross-account access)
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
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${var.management_account_id}:role/github-actions-*"]
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
