variable "account_name" {
  type = string
}

variable "email" {
  type = string
}

variable "management_account_id" {
  type = string
}

variable "organization_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
