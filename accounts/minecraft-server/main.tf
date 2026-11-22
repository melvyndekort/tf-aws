module "account_bootstrap" {
  source = "../../modules/account-bootstrap"

  management_account_id       = var.management_account_id
  organization_id             = var.organization_id
  melvyn_user_arn             = "arn:aws:iam::${var.management_account_id}:user/melvyn"
  yubikey_role_arn            = "arn:aws:iam::${var.management_account_id}:role/YubikeyRole"
  notifications_sns_topic_arn = "arn:aws:sns:eu-west-1:${var.management_account_id}:aws-notifications"

  terraform_plan_role_trusted_principal_arns = [
    "arn:aws:iam::520519513359:role/ec2Role-hermes-agent",
    "arn:aws:iam::${var.management_account_id}:role/external/github-actions-tf-aws-plan",
  ]
}
