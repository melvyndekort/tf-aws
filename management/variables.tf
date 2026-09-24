variable "account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "admin_email" {
  description = "Administrator email address"
  type        = string
}

variable "api_domain" {
  description = "API subdomain"
  type        = string
}

variable "pgp_key" {
  type = string
}

variable "subaccount_secret_targets" {
  description = <<-EOT
    Encryption-context `target` values that org principals outside this account
    may encrypt/decrypt on alias/generic.

    Deliberately an explicit allow-list, not a wildcard: every repo's secrets.tf
    already uses a unique `target`, so listing them here means a subaccount repo
    can reach its own secrets and nothing else. A wildcard would expose every
    management-account secret on this key to any principal in the org.
  EOT

  type    = list(string)
  default = ["hermes-agent"]
}
