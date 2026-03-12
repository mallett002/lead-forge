terraform {
  required_version = "1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.35.1"
    }
  }

  backend "s3" {
    bucket         = "lead-forge-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lead_forge_terraform_locks_table"
  }
}

provider "aws" {
  region = "us-east-1"
}

