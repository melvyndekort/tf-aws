resource "aws_organizations_account" "account" {
  name      = var.account_name
  email     = var.email
  role_name = "OrganizationAccountAccessRole"
  tags      = var.tags
}

data "aws_iam_policy_document" "admin_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession", "sts:SetSourceIdentity"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:role/YubikeyRole"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.organization_id]
    }
  }
}

provider "aws" {
  alias = "subaccount"
  
  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.account.id}:role/OrganizationAccountAccessRole"
  }
}

resource "aws_iam_role" "admin" {
  provider           = aws.subaccount
  name               = "AdminRole"
  assume_role_policy = data.aws_iam_policy_document.admin_assume.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  provider   = aws.subaccount
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
