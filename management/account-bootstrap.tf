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

# Outputs
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.account_bootstrap.github_oidc_provider_arn
}

output "tf_github_role_arn" {
  description = "ARN of the tf-github repository role"
  value       = module.account_bootstrap.tf_github_role_arn
}
