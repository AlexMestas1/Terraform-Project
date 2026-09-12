provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  backend "s3" {
    bucket  = "alexmestas-terraform-state"
    key     = "build/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}
