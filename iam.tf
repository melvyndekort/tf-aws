# PASSWORD POLICY
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 40
  max_password_age               = 89
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}



# MFA ASSUME
data "aws_iam_policy_document" "mfa_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = [
        aws_iam_user.melvyn.arn
      ]
    }

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"

      values = [
        "true",
      ]
    }
  }
}



# AWS MANAGED POLICIES
data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

data "aws_iam_policy" "billing_read_only" {
  name = "AWSBillingReadOnlyAccess"
}

data "aws_iam_policy" "account_usage_report" {
  name = "AWSAccountUsageReportAccess"
}

data "aws_iam_policy" "sns" {
  name = "AmazonSNSFullAccess"
}



# CUSTOM POLICIES
data "aws_iam_policy_document" "ec2_deny" {
  statement {
    effect = "Deny"

    actions = [
      "ec2:*",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "ec2:Region"

      values = [
        "eu-west-1",
      ]
    }
  }
}



# ADMIN ROLE
resource "aws_iam_role" "admin" {
  name               = "AdminRole"
  assume_role_policy = data.aws_iam_policy_document.mfa_assume.json
}

resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.admin.name
  policy_arn = data.aws_iam_policy.admin.arn
}

resource "aws_iam_role_policy" "admin_ec2_deny" {
  role   = aws_iam_role.admin.name
  policy = data.aws_iam_policy_document.ec2_deny.json
}



# FINANCE ROLE
resource "aws_iam_role" "finance" {
  name               = "FinanceRole"
  assume_role_policy = data.aws_iam_policy_document.mfa_assume.json
}

resource "aws_iam_role_policy_attachment" "finance_billing_policy" {
  role       = aws_iam_role.finance.name
  policy_arn = data.aws_iam_policy.billing_read_only.arn
}

resource "aws_iam_role_policy_attachment" "finance_usage_policy" {
  role       = aws_iam_role.finance.name
  policy_arn = data.aws_iam_policy.account_usage_report.arn
}



# GITHUB ACTIONS ROLE
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:melvyndekort/tf-aws:ref:refs/heads/main"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = ["melvyndekort/tf-aws"]
    }
  }
}

resource "aws_iam_role" "github_actions_tf_aws" {
  name               = "github-actions-tf-aws"
  path               = "/external/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = [
      "acm:*",
      "apigateway:*",
      "autoscaling:*",
      "cloudfront:*",
      "cloudwatch:*",
      "codebuild:*",
      "codestar-notifications:*",
      "cognito:*",
      "cognito-idp:*",
      "ec2:*",
      "ecr:*",
      "ecs:*",
      "events:*",
      "iam:*",
      "lambda:*",
      "logs:*",
      "pipes:*",
      "s3:*",
      "sns:*",
      "sqs:*",
      "ssm:*",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:CreateGrant",
    ]

    resources = [
      aws_kms_key.generic.arn,
      data.aws_kms_key.default_s3.arn,
    ]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  role   = aws_iam_role.github_actions_tf_aws.name
  policy = data.aws_iam_policy_document.github_actions.json
}

resource "aws_iam_role_policy" "github_actions_ec2_deny" {
  role   = aws_iam_role.github_actions_tf_aws.name
  policy = data.aws_iam_policy_document.ec2_deny.json
}



# HOME ASSISTANT USER
resource "aws_iam_user_policy_attachment" "homeassistant_sns" {
  user = aws_iam_user.homeassistant.name
  policy_arn = data.aws_iam_policy.sns.arn
}

data "aws_iam_policy_document" "homeassistant" {
  statement {
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.generic.arn,
    ]
  }
}

resource "aws_iam_user_policy" "homeassistant" {
  user = aws_iam_user.homeassistant.name
  policy = data.aws_iam_policy_document.homeassistant.json
}
