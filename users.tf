# MELVYN USER
resource "aws_iam_user" "melvyn" {
  name = "melvyn"
  path = "/"
}

resource "aws_iam_access_key" "melvyn" {
  user = aws_iam_user.melvyn.name
}

resource "aws_iam_user_login_profile" "melvyn" {
  user            = aws_iam_user.melvyn.name
  password_length = 40
  pgp_key         = var.pgp_key
}

# LMBACKUP USER
resource "aws_iam_user" "lmbackup" {
  name = "lmbackup"
  path = "/automated/"
}

resource "aws_iam_access_key" "lmbackup" {
  user = aws_iam_user.lmbackup.name
}

# HOME ASSISTANT USER
resource "aws_iam_user" "homeassistant" {
  name = "homeassistant"
  path = "/automated/"
}

resource "aws_iam_access_key" "homeassistant" {
  user = aws_iam_user.homeassistant.name
}
