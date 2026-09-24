data "aws_iam_policy_document" "kms_generic" {
  statement {
    actions = [
      "kms:*",
    ]

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"

      values = [
        "arn:aws:cloudtrail:*:${var.account_id}:trail/*",
      ]
    }
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt*"
    ]

    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_user.lmbackup.arn,
        aws_iam_user.homeassistant.arn,
      ]
    }
  }

  # Let principals in other org accounts use this key, but ONLY for their own
  # repo's secrets. Without the EncryptionContext condition an org-wide grant
  # would let any principal in any account decrypt EVERY secret on this key,
  # including the management-account ones (tf-github, tf-backup, tf-cloudflare,
  # email-infra, aws-ntfy-alerts, tf-grafana, tf-minecraft) - a significant
  # widening, since today those are reachable only from this account.
  #
  # `target` is already unique per repo in every secrets.tf, so it is the
  # natural boundary: subaccount repos are listed explicitly below and get
  # access to nothing else.
  statement {
    sid = "OrgAccountsScopedToOwnSecrets"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
    ]

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"

      values = [
        aws_organizations_organization.organization.id,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:target"

      values = var.subaccount_secret_targets
    }
  }

  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.eu-west-1.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:eu-west-1:${var.account_id}:log-group:*",
      ]
    }
  }
}

resource "aws_kms_key" "generic" {
  description         = "Encrypt/decrypt of secrets and Terraform state files"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_generic.json
}

resource "aws_kms_alias" "generic" {
  name          = "alias/generic"
  target_key_id = aws_kms_key.generic.key_id
}

data "aws_kms_alias" "default_s3" {
  name = "alias/aws/s3"
}

data "aws_kms_key" "default_s3" {
  key_id = data.aws_kms_alias.default_s3.arn
}
