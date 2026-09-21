provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket  = "alexmestas-terraform-state"
    key     = "build/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}
