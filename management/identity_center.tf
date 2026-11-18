# AWS IAM Identity Center — permission sets + account assignments
#
# Identity source (external IdP via Authentik, SAML + SCIM) was bootstrapped
# manually in the Console on 2026-11-18 — that step has no Terraform/API support
# at all (confirmed: CreateApplication only supports custom OAuth2 apps; 3rd-party
# SAML setup is Console-only). Everything from here on (permission sets, account
# assignments) is fully Terraform-managed, per convention.
#
# Sync scope: the "aws-users" Authentik group (SCIM-provisioned into Identity
# Center already) is the only principal assigned anything below — starts with
# just Melvyn, same single-admin pattern as every other app in the Authentik
# expansion plan.

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  sso_identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  identity_center_accounts = {
    management      = data.aws_caller_identity.current.account_id
    hermes_agent    = module.hermes_agent.account_id
    network_monitor = module.network_monitor.account_id
  }
}

data "aws_identitystore_group" "aws_users" {
  identity_store_id = local.sso_identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "aws-users"
    }
  }
}

# PERMISSION SETS

resource "aws_ssoadmin_permission_set" "administrator" {
  name             = "AdministratorAccess"
  description      = "Full administrator access (Authentik SSO)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_permission_set" "read_only" {
  name             = "ReadOnlyAccess"
  description      = "Read-only access (Authentik SSO)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ACCOUNT ASSIGNMENTS — both permission sets, every account, aws-users group

resource "aws_ssoadmin_account_assignment" "administrator" {
  for_each = local.identity_center_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator.arn

  principal_id   = data.aws_identitystore_group.aws_users.group_id
  principal_type = "GROUP"

  target_id   = each.value
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "read_only" {
  for_each = local.identity_center_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn

  principal_id   = data.aws_identitystore_group.aws_users.group_id
  principal_type = "GROUP"

  target_id   = each.value
  target_type = "AWS_ACCOUNT"
}
