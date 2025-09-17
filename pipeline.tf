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
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:melvyndekort/tf-aws:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_tf_aws" {
  name               = "github-actions-tf-aws"
  path               = "/external/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions_tf_aws.name
  policy_arn = data.aws_iam_policy.admin.arn
}

resource "aws_iam_role_policy" "github_actions_ec2_deny" {
  role   = aws_iam_role.github_actions_tf_aws.name
  policy = data.aws_iam_policy_document.ec2_deny.json
}
