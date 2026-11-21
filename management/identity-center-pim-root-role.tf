# Narrow management-account role for the aws-idc-pim JIT elevation bot.
#
# Delegated administration (aws_organizations_delegated_administrator.aws_idc_pim
# above) lets aws-idc-pim's Lambda manage account assignments for workload
# accounts directly. It cannot manage assignments targeting the management
# account itself (AWS hard-restricts that regardless of delegation) -- this
# role is the one narrow exception, assumed by that same Lambda only when a
# request targets the management account.
#
# Trust is pinned to the Lambda's execution role by its deterministic name
# (aws-idc-pim-lambda-role in 397379012163) rather than a Terraform reference
# across repos -- same idiom as terraform_plan_role_trusted_principal_arns
# elsewhere in this file: a hardcoded ARN string, not a live dependency, so
# apply order between the two repos doesn't matter.
#
# Scoped to exactly the AdministratorAccess permission set ARN -- this role
# cannot touch ReadOnlyAccess or any future permission set. It is NOT scoped
# to a specific target_id (IAM Identity Center's sso-admin API has no
# documented resource-level condition key for the assignment's target
# account), so in principle this role's holder could assign AdministratorAccess
# to any account, not just the management account. Accepted at this scale:
# enforcement that it's only ever used for management-account requests lives
# in the Lambda's own code path + the single-user Discord allow-list +
# CloudTrail, not in this policy. Revisit if sso-admin ever adds a target
# condition key.
data "aws_iam_policy_document" "idc_pim_root_elevation_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    # IAM's CreateRole validates an "AWS" principal that names a specific
    # role ARN against roles that EXIST AT CREATION TIME -- the Lambda role
    # below doesn't exist yet (its own repo's Terraform hasn't applied),
    # so a direct role-ARN principal gets rejected with
    # MalformedPolicyDocument (confirmed live on tf-aws#32's first apply).
    # The account-root + aws:PrincipalArn condition form is validated
    # lazily instead -- it's the standard way to trust a specific role
    # that doesn't exist yet, or that gets recreated over time.
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::397379012163:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::397379012163:role/aws-idc-pim-lambda-role"]
    }
  }
}

resource "aws_iam_role" "idc_pim_root_elevation" {
  name               = "IdcPimRootElevationRole"
  description        = "Narrow role for aws-idc-pim's JIT bot to elevate/revoke AdministratorAccess on the management account itself"
  assume_role_policy = data.aws_iam_policy_document.idc_pim_root_elevation_trust.json
}

data "aws_iam_policy_document" "idc_pim_root_elevation_permissions" {
  statement {
    sid    = "ManageAdministratorAccessAssignments"
    effect = "Allow"
    actions = [
      "sso-admin:CreateAccountAssignment",
      "sso-admin:DeleteAccountAssignment",
      "sso-admin:DescribeAccountAssignmentCreationStatus",
      "sso-admin:DescribeAccountAssignmentDeletionStatus",
    ]
    resources = [aws_ssoadmin_permission_set.administrator.arn]
  }

  statement {
    sid       = "ResolveIdentityStorePrincipals"
    effect    = "Allow"
    actions   = ["identitystore:ListUsers"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "idc_pim_root_elevation" {
  name   = "manage-administrator-access-assignments"
  role   = aws_iam_role.idc_pim_root_elevation.id
  policy = data.aws_iam_policy_document.idc_pim_root_elevation_permissions.json
}

output "idc_pim_root_elevation_role_arn" {
  description = "ARN of the narrow role aws-idc-pim assumes for management-account elevation requests"
  value       = aws_iam_role.idc_pim_root_elevation.arn
}
