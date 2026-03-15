terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket       = "mdekort-tfstate-844347863910"
    key          = "tf-aws.tfstate"
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
  
  # For GitHub Actions
  assume_role {
    role_arn = "arn:aws:iam::844347863910:role/OrganizationAccountAccessRole"
  }
}
