# Account Bootstrap (GitHub OIDC + AdminRole)
data "aws_caller_identity" "current" {}

module "account_bootstrap" {
  source = "../modules/account-bootstrap"

  management_account_id = data.aws_caller_identity.current.account_id
  organization_id       = aws_organizations_organization.organization.id
  melvyn_user_arn       = aws_iam_user.melvyn.arn
  yubikey_role_arn      = aws_iam_role.yubikey_role.arn
}

# EC2 regional restriction for AdminRole
resource "aws_iam_role_policy" "admin_ec2_deny" {
  role   = module.account_bootstrap.admin_role_name
  policy = data.aws_iam_policy_document.ec2_deny.json
}

# tf-aws's own read-only PR-plan role. Looked up by name rather than by a
# Terraform reference because it is NOT created here -- it comes from
# tf-github's generic oidc_role module, opted in via `aws_plan_role: true`
# in tf-github's repos/tf-aws.yaml. Apply order across repos: tf-github
# creates this role first (it must exist in AWS before this data source
# resolves), then this grant can attach.
data "aws_iam_role" "tf_aws_plan" {
  name = "github-actions-tf-aws-plan"
}

# Management-only grant for tf-aws's own plan role: it must additionally
# assume the read-only TerraformPlanRole in each subaccount tf-aws plans
# (accounts/hermes-agent, accounts/network-monitor), the same shape as the
# tf-github-plan grant below. ReadOnlyAccess does not include sts:AssumeRole,
# so this is required for the subaccounts PR-plan job's provider to assume
# TerraformPlanRole instead of the admin OrganizationAccountAccessRole.
data "aws_iam_policy_document" "tf_aws_plan_assume_subaccounts" {
  statement {
    sid       = "AssumeSubaccountPlanRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/TerraformPlanRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [aws_organizations_organization.organization.id]
    }
  }
}

resource "aws_iam_role_policy" "tf_aws_plan_assume_subaccounts" {
  name   = "assume-subaccount-plan-roles"
  role   = data.aws_iam_role.tf_aws_plan.name
  policy = data.aws_iam_policy_document.tf_aws_plan_assume_subaccounts.json
}

# Management-only grants for the tf-github plan role. Same shape as the
# admin_ec2_deny attachment above: the module creates the role in every
# account, the management account adds what only it needs.
#
# tf-github manages IAM roles in every account, so its plan refreshes
# cross-account and the management role must reach the subaccount plan roles.
# ReadOnlyAccess does not include sts:AssumeRole, so this grant is required -
# simulate-principal-policy returns implicitDeny without it.
data "aws_iam_policy_document" "tf_github_plan_assume_subaccounts" {
  statement {
    sid       = "AssumeSubaccountPlanRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/external/github-actions-tf-github-plan"]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [aws_organizations_organization.organization.id]
    }
  }
}

resource "aws_iam_role_policy" "tf_github_plan_assume_subaccounts" {
  name   = "assume-subaccount-plan-roles"
  role   = module.account_bootstrap.tf_github_plan_role_name
  policy = data.aws_iam_policy_document.tf_github_plan_assume_subaccounts.json
}

# tf-github's plan decrypts target=tf-github secrets. ReadOnlyAccess covers
# kms:Describe*/Get*/List* but not kms:Decrypt, and the key is management-only.
data "aws_iam_policy_document" "tf_github_plan_kms_decrypt" {
  statement {
    sid       = "DecryptPlanSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.generic.arn]

    # Only tf-github's own secret, not every secret on the shared key.
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"
      values   = ["tf-github"]
    }
  }
}

resource "aws_iam_role_policy" "tf_github_plan_kms_decrypt" {
  name   = "kms-decrypt"
  role   = module.account_bootstrap.tf_github_plan_role_name
  policy = data.aws_iam_policy_document.tf_github_plan_kms_decrypt.json
}

# ReadOnlyRole decrypts the secrets of the repos whose drift check plans in this
# account. ReadOnlyAccess covers kms:Describe*/Get*/List* but not kms:Decrypt.
# Scoped to one key AND an explicit encryption-context allow-list, so the role
# cannot decrypt any other secret on alias/generic (e.g. email-infra's).
# Same account as the key, whose policy delegates to the account root, so an
# identity-policy grant suffices. The state bucket is AES256, no KMS involved.
data "aws_iam_policy_document" "readonly_kms_decrypt" {
  statement {
    sid       = "DecryptDriftCheckSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.generic.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"
      values   = ["tf-github", "tf-cloudflare", "tf-grafana", "tf-backup"]
    }
  }
}

resource "aws_iam_role_policy" "readonly_kms_decrypt" {
  name   = "kms-decrypt"
  role   = module.account_bootstrap.readonly_role_name
  policy = data.aws_iam_policy_document.readonly_kms_decrypt.json
}

# TerraformPlanRole decrypts the secrets of the repos the drift check plans in this
# account, same target allow-list as the ReadOnlyRole grant it replaces.
data "aws_iam_policy_document" "terraform_plan_kms_decrypt" {
  statement {
    sid       = "DecryptPlanSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.generic.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"
      values   = ["tf-github", "tf-cloudflare", "tf-grafana", "tf-backup"]
    }
  }
}

resource "aws_iam_role_policy" "terraform_plan_kms_decrypt" {
  name   = "kms-decrypt"
  role   = module.account_bootstrap.terraform_plan_role_name
  policy = data.aws_iam_policy_document.terraform_plan_kms_decrypt.json
}

# Outputs
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.account_bootstrap.github_oidc_provider_arn
}

output "tf_github_role_arn" {
  description = "ARN of the tf-github repository role"
  value       = module.account_bootstrap.tf_github_role_arn
}

output "readonly_role_arn" {
  description = "ARN of the ReadOnlyRole"
  value       = module.account_bootstrap.readonly_role_arn
}

output "tf_github_plan_role_arn" {
  description = "ARN of the read-only tf-github PR plan role"
  value       = module.account_bootstrap.tf_github_plan_role_arn
}
