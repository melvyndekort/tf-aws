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
#
# Trust-policy shape (immutable-subject, environment-pinned OIDC federation)
# shared with tf-github's own oidc_role module via gha-workflows'
# oidc-github-trust-policy module -- see that module's README. The
# cross-account self-reference statement below is specific to this role
# (tf-github provisions its own apply role in every OTHER account, so it
# needs to assume itself cross-account while bootstrapping those), so it's
# merged in here rather than folded into the shared module.
module "tf_github_trust" {
  source = "git::https://github.com/melvyndekort/gha-workflows.git//modules/oidc-github-trust-policy?ref=feat/oidc-trust-policy-module"

  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  github_org        = "melvyndekort"
  github_owner_id   = var.tf_github_owner_id
  repo_name         = "tf-github"
  repo_id           = var.tf_github_repo_id
}

data "aws_iam_policy_document" "tf_github_assume" {
  source_policy_documents = [module.tf_github_trust.apply_assume_role_policy_json]

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
#
# Trust-policy shape shared via the same oidc-github-trust-policy module as
# the apply role above; the cross-account self-reference statement is merged
# in the same way.
module "tf_github_plan_trust" {
  source = "git::https://github.com/melvyndekort/gha-workflows.git//modules/oidc-github-trust-policy?ref=feat/oidc-trust-policy-module"

  oidc_provider_arn      = aws_iam_openid_connect_provider.github.arn
  github_org             = "melvyndekort"
  github_owner_id        = var.tf_github_owner_id
  repo_name              = "tf-github"
  repo_id                = var.tf_github_repo_id
  create_apply_document  = false
  create_plan_document   = true
  plan_job_workflow_refs = var.plan_job_workflow_refs
}

data "aws_iam_policy_document" "tf_github_plan_assume" {
  source_policy_documents = [module.tf_github_plan_trust.plan_assume_role_policy_json]

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

  # tf-github's own apply role, from the management account (for cross-account
  # access while it provisions other repos' OIDC roles in this account).
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

# ---------------------------------------------------------------------------
# OIDC-assumption monitoring (tf-github improvement plan Phase 2 item 2)
#
# Finding 1 (security audit) accepts that every github-actions-* role is
# effectively AdministratorAccess, fleet-wide, with no narrower-scope retry
# planned (canaried, reverted, Melvyn's call -- see the plan's §2 "explicitly
# deferred"). Detection is therefore the only compensating control left:
# alert on every AssumeRoleWithWebIdentity against a github-actions-* role in
# every account, not just management.
#
# Each account gets its own rule (CloudTrail/EventBridge events are
# account+region-local; there's no org trail aggregating them onto one bus
# today), but publishes to the single SNS topic already used for every other
# notification -- cross-account to the management account's topic for
# subaccounts, same-account for the management account itself. This mirrors
# the existing `tf_github_ref_based_assume` rule in
# management/notifications-monitoring.tf (now a strict subset of this one)
# rather than inventing a second notification path.
resource "aws_iam_role" "eventbridge_oidc_notifications" {
  count = var.notifications_sns_topic_arn != "" ? 1 : 0

  name = "eventbridge-oidc-notifications-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_oidc_notifications" {
  count = var.notifications_sns_topic_arn != "" ? 1 : 0

  name = "eventbridge-oidc-notifications-policy"
  role = aws_iam_role.eventbridge_oidc_notifications[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.notifications_sns_topic_arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "github_actions_assume_role" {
  count = var.notifications_sns_topic_arn != "" ? 1 : 0

  name        = "github-actions-assume-role-notifications"
  description = "Alert on AssumeRoleWithWebIdentity against any github-actions-* role in this account (every such role is effectively AdministratorAccess; detection is the compensating control)"

  event_pattern = jsonencode({
    "source" : ["aws.sts"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["sts.amazonaws.com"],
      "eventName" : ["AssumeRoleWithWebIdentity"],
      "requestParameters" : {
        "roleArn" : [{ "wildcard" : "*role/external/github-actions-*" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "github_actions_assume_role" {
  count = var.notifications_sns_topic_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.github_actions_assume_role[0].name
  target_id = "GithubActionsAssumeRoleNotificationsTarget"
  arn       = var.notifications_sns_topic_arn
  role_arn  = aws_iam_role.eventbridge_oidc_notifications[0].arn
}
