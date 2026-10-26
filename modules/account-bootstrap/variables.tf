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

variable "readonly_role_trusted_principal_arns" {
  description = "IAM principal ARNs trusted to assume ReadOnlyRole. Currently the Hermes Agent ECS task role and, for its move from ECS to EC2, the Hermes Agent EC2 instance role (drop the ECS one once the migration is done); add more to extend read-only cross-account access to other principals. IAM resolves each ARN to the role's unique ID when the policy is saved, so a deleted and recreated role must be applied again."
  type        = list(string)
  default = [
    "arn:aws:iam::520519513359:role/ecsTaskRole-hermes-agent",
    "arn:aws:iam::520519513359:role/ec2Role-hermes-agent",
  ]
}


variable "terraform_plan_role_trusted_principal_arns" {
  description = "IAM principal ARNs trusted to assume TerraformPlanRole. Currently the Hermes Agent ECS task role and, for its move from ECS to EC2, the Hermes Agent EC2 instance role (drop the ECS one once the migration is done)."
  type        = list(string)
  default = [
    "arn:aws:iam::520519513359:role/ecsTaskRole-hermes-agent",
    "arn:aws:iam::520519513359:role/ec2Role-hermes-agent",
  ]
}

variable "plan_job_workflow_refs" {
  description = <<-EOT
    Reusable workflows allowed to assume the tf-github plan role, matched on the
    job_workflow_ref OIDC claim. This is the real boundary that stops
    PR-authored workflow code from using the role.
  EOT

  type    = list(string)
  default = ["melvyndekort/gha-workflows/.github/workflows/terraform-pr-plan.yml@*"]
}

