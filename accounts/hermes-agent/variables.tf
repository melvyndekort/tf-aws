variable "management_account_id" {
  description = "AWS account ID of the management account"
  type        = string
  default     = "075673041815"
}

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

# Cross-account role to assume via providers.tf: the admin
# OrganizationAccountAccessRole for applies (default), the read-only
# TerraformPlanRole for PR plans. Overridden by TF_VAR_subaccount_role_name,
# set by the terraform-pr-plan.yml reusable workflow in .github/workflows/
# terraform.yml. Not secret (public Terraform, visible in any PR); safe
# because the plan role's own IAM policy, not this variable, is what
# actually authorises the assume -- see
# modules/account-bootstrap/variables.tf's terraform_plan_role_trusted_principal_arns.
variable "subaccount_role_name" {
  description = "Cross-account role to assume: OrganizationAccountAccessRole for applies, TerraformPlanRole for PR plans"
  type        = string
  default     = "OrganizationAccountAccessRole"
}
