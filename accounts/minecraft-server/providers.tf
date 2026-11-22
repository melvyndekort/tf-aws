terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket       = "mdekort-tfstate-075673041815"
    key          = "tf-aws-minecraft-server.tfstate"
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

  assume_role {
    role_arn = "arn:aws:iam::805751386945:role/${var.subaccount_role_name}"
  }
}
