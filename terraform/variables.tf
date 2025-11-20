variable "account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "tfstate_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
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
