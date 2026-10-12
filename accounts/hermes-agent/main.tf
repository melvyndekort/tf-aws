module "account_bootstrap" {
  source = "../../modules/account-bootstrap"

  management_account_id = var.management_account_id
  organization_id       = var.organization_id
  melvyn_user_arn       = "arn:aws:iam::${var.management_account_id}:user/melvyn"
  yubikey_role_arn      = "arn:aws:iam::${var.management_account_id}:role/YubikeyRole"
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
