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
    for acct in aws_organizations_organization.organization.accounts :
    acct.id => acct.id if acct.status == "ACTIVE"
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

# ACCOUNT ASSIGNMENTS — ReadOnlyAccess standing for every account, aws-users group

resource "aws_ssoadmin_account_assignment" "read_only" {
  for_each = local.identity_center_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn

  principal_id   = data.aws_identitystore_group.aws_users.group_id
  principal_type = "GROUP"

  target_id   = each.value
  target_type = "AWS_ACCOUNT"
}

# Delegated administration — registers aws-idc-pim as the IAM Identity
# Center delegated admin. From here on, most Identity Center admin API
# calls (incl. create/delete-account-assignment for workload accounts, the
# core operation of the planned JIT elevation bot) can run from aws-idc-pim
# instead of the management account. AWS hard-restricts the delegated admin
# from managing assignments/permission sets targeting the management
# account itself — that case stays handled separately, via a narrow
# cross-account role rather than by granting this account broader reach.
# sso.amazonaws.com is already an enabled trusted service (see
# aws_organizations_organization.organization in organizations.tf), so no
# further Organizations-level prerequisite is needed.
resource "aws_organizations_delegated_administrator" "aws_idc_pim" {
  account_id        = module.aws_idc_pim.account_id
  service_principal = "sso.amazonaws.com"
}
