output "account_id" {
  description = "AWS account ID"
  value       = aws_organizations_account.account.id
}

output "account_arn" {
  description = "ARN of the AWS account"
  value       = aws_organizations_account.account.arn
}
