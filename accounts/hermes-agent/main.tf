module "account_bootstrap" {
  source = "../../modules/account-bootstrap"

  management_account_id = var.management_account_id
  organization_id       = var.organization_id
  melvyn_user_arn       = "arn:aws:iam::${var.management_account_id}:user/melvyn"
  yubikey_role_arn      = "arn:aws:iam::${var.management_account_id}:role/YubikeyRole"

  # Default (Hermes Agent EC2 instance role, for the weekly drift check) plus
  # tf-aws's own PR-plan role, so the terraform-pr-plan.yml reusable workflow
  # can assume this account's read-only TerraformPlanRole when planning
  # accounts/hermes-agent on a pull request. The plan role itself is created
  # by tf-github (github-actions-tf-aws-plan, opted in via aws_plan_role: true
  # in tf-github's repos/tf-aws.yaml); the matching sts:AssumeRole grant onto
  # this role lives in management/account-bootstrap.tf.
  terraform_plan_role_trusted_principal_arns = [
    "arn:aws:iam::520519513359:role/ec2Role-hermes-agent",
    "arn:aws:iam::075673041815:role/external/github-actions-tf-aws-plan",
  ]
}

# ReadOnlyRole decrypts hermes-agent's own secrets for the drift check. The key
# lives in the management account, so the key policy's org-scoped statement
# (OrgAccountsScopedToOwnSecrets, target in subaccount_secret_targets)
# must also allow it - this identity grant is the other half. ReadOnlyAccess has
# no kms:Decrypt. Scoped to the one key and the one encryption-context target.
data "aws_iam_policy_document" "readonly_kms_decrypt" {
  statement {
    sid       = "DecryptDriftCheckSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.terraform_remote_state.management.outputs.generic_kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"
      values   = ["hermes-agent"]
    }
  }
}

resource "aws_iam_role_policy" "readonly_kms_decrypt" {
  name   = "kms-decrypt"
  role   = module.account_bootstrap.readonly_role_name
  policy = data.aws_iam_policy_document.readonly_kms_decrypt.json
}

# TerraformPlanRole decrypts hermes-agent's own secret for the drift check.
# Cross-account: the key policy statement OrgAccountsScopedToOwnSecrets already
# allows org principals for target hermes-agent, so no key-policy change.
data "aws_iam_policy_document" "terraform_plan_kms_decrypt" {
  statement {
    sid       = "DecryptPlanSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.terraform_remote_state.management.outputs.generic_kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"
      values   = ["hermes-agent"]
    }
  }
}

resource "aws_iam_role_policy" "terraform_plan_kms_decrypt" {
  name   = "kms-decrypt"
  role   = module.account_bootstrap.terraform_plan_role_name
  policy = data.aws_iam_policy_document.terraform_plan_kms_decrypt.json
}
