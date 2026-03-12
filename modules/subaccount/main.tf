resource "aws_organizations_account" "account" {
  name      = var.account_name
  email     = var.email
  role_name = "OrganizationAccountAccessRole"
  tags      = var.tags
}

# State bucket for subaccount (created in management account)
resource "aws_s3_bucket" "subaccount_tfstate" {
  bucket = "mdekort-${var.account_name}-tfstate"
}

resource "aws_s3_bucket_versioning" "subaccount_tfstate" {
  bucket = aws_s3_bucket.subaccount_tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "subaccount_tfstate" {
  bucket = aws_s3_bucket.subaccount_tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Allow subaccount AdminRole to access state bucket
data "aws_iam_policy_document" "subaccount_tfstate" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.account.id}:role/AdminRole"]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.subaccount_tfstate.arn,
      "${aws_s3_bucket.subaccount_tfstate.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "subaccount_tfstate" {
  bucket = aws_s3_bucket.subaccount_tfstate.id
  policy = data.aws_iam_policy_document.subaccount_tfstate.json
}
