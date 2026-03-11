output "account_id" {
  value = aws_organizations_account.account.id
}

output "account_arn" {
  value = aws_organizations_account.account.arn
}

output "admin_role_arn" {
  value = aws_iam_role.admin.arn
}
