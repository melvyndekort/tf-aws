output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.account_bootstrap.github_oidc_provider_arn
}

output "tf_github_role_arn" {
  description = "ARN of the tf-github repository role"
  value       = module.account_bootstrap.tf_github_role_arn
}

output "admin_role_arn" {
  description = "ARN of the AdminRole"
  value       = module.account_bootstrap.admin_role_arn
}
