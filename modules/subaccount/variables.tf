variable "account_name" {
  description = "Name of the AWS account"
  type        = string
}

variable "email" {
  description = "Email address for the AWS account"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the account"
  type        = map(string)
  default     = {}
}
