module "account_bootstrap" {
  source = "../../modules/account-bootstrap"

  management_account_id       = var.management_account_id
  organization_id             = var.organization_id
  melvyn_user_arn             = "arn:aws:iam::${var.management_account_id}:user/melvyn"
  yubikey_role_arn            = "arn:aws:iam::${var.management_account_id}:role/YubikeyRole"
  notifications_sns_topic_arn = "arn:aws:sns:eu-west-1:${var.management_account_id}:aws-notifications"
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
