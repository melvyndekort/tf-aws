variable "management_account_id" {
  description = "AWS account ID of the management account"
  type        = string
}

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "melvyn_user_arn" {
  description = "ARN of the melvyn IAM user"
  type        = string
}

variable "yubikey_role_arn" {
  description = "ARN of the YubikeyRole in the management account"
  type        = string
}

variable "tf_github_owner_id" {
  description = "Numeric GitHub owner ID for melvyndekort, used in the immutable-subject OIDC claim"
  type        = number
  default     = 359886
}

variable "tf_github_repo_id" {
  description = "Numeric GitHub repo ID for melvyndekort/tf-github, used in the immutable-subject OIDC claim"
  type        = number
  default     = 1057394177
}
