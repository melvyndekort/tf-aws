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
  }
}

resource "aws_iam_role_policy" "tf_github_plan_kms_decrypt" {
  name   = "kms-decrypt"
  role   = module.account_bootstrap.tf_github_plan_role_name
  policy = data.aws_iam_policy_document.tf_github_plan_kms_decrypt.json
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
