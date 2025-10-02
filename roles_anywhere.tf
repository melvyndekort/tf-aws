resource "aws_rolesanywhere_trust_anchor" "yubikey_ca" {
  name    = "melvyn-yubikey-ca"
  enabled = true

  source {
    source_type = "CERTIFICATE_BUNDLE"

    source_data {
      x509_certificate_data = file("${path.module}/files/yubikey-ca.crt")
    }
  }
}

data "aws_iam_policy_document" "rolesanywhere_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]

    principals {
      type = "Service"
      identifiers = [
        "rolesanywhere.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Subject/OU"
      values   = ["MelvynYubikey"]
    }
  }
}

resource "aws_iam_role" "yubikey_role" {
  name               = "YubikeyRole"
  assume_role_policy = data.aws_iam_policy_document.rolesanywhere_assume.json
}

resource "aws_rolesanywhere_profile" "yubikey_profile" {
  name      = "melvyn-yubikey-profile"
  role_arns = [aws_iam_role.yubikey_role.arn]
  enabled   = true
}

data "aws_iam_policy_document" "yubikey_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]
    resources = [
      aws_iam_role.admin.arn,
      aws_iam_role.finance.arn,
    ]
  }
}

resource "aws_iam_role_policy" "yubikey_policy" {
  role   = aws_iam_role.yubikey_role.name
  policy = data.aws_iam_policy_document.yubikey_policy.json
}
