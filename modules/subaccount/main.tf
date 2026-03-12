resource "aws_organizations_account" "account" {
  name      = var.account_name
  email     = var.email
  role_name = "OrganizationAccountAccessRole"
  tags      = var.tags
}
