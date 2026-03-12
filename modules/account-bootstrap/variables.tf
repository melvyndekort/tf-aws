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
