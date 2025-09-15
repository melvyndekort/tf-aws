terraform {
  required_version = "~> 1.6.0"

  backend "s3" {
    bucket = "mdekort.tfstate"
    key    = "tf-aws.tfstate"
    region = "eu-west-1"
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
}

provider "awscc" {
  region = "eu-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "useast1"
}
