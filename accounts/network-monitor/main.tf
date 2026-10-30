module "account_bootstrap" {
  source = "../../modules/account-bootstrap"

  management_account_id = var.management_account_id
  organization_id       = var.organization_id
  melvyn_user_arn       = "arn:aws:iam::${var.management_account_id}:user/melvyn"
  yubikey_role_arn      = "arn:aws:iam::${var.management_account_id}:role/YubikeyRole"

  # Default (Hermes Agent EC2 instance role, for the weekly drift check) plus
  # tf-aws's own PR-plan role, so the terraform-pr-plan.yml reusable workflow
  # can assume this account's read-only TerraformPlanRole when planning
  # accounts/network-monitor on a pull request. The plan role itself is
  # created by tf-github (github-actions-tf-aws-plan, opted in via
  # aws_plan_role: true in tf-github's repos/tf-aws.yaml); the matching
  # sts:AssumeRole grant onto this role lives in management/account-bootstrap.tf.
  terraform_plan_role_trusted_principal_arns = [
    "arn:aws:iam::520519513359:role/ec2Role-hermes-agent",
    "arn:aws:iam::075673041815:role/external/github-actions-tf-aws-plan",
  ]
}
