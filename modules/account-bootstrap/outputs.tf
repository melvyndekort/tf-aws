output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "tf_github_role_arn" {
  description = "ARN of the tf-github repository role"
  value       = aws_iam_role.tf_github.arn
}

output "admin_role_arn" {
  description = "ARN of the AdminRole for cross-account access"
  value       = aws_iam_role.admin.arn
}

output "admin_role_name" {
  description = "Name of the AdminRole"
  value       = aws_iam_role.admin.name
}

output "tfstate_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = aws_s3_bucket.tfstate.id
}
