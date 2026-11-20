terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket       = "mdekort-tfstate-075673041815"
    key          = "tf-aws-hermes-agent.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"

  # Role assumed cross-account differs by trigger: applies use the admin
  # OrganizationAccountAccessRole (default), PR plans override it to the
  # read-only TerraformPlanRole via TF_VAR_subaccount_role_name, set by the
  # terraform-pr-plan.yml reusable workflow. See variables.tf.
  assume_role {
    role_arn = "arn:aws:iam::520519513359:role/${var.subaccount_role_name}"
  }
}
