terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Default provider for the ENG account (where your app is deployed)
# This will be used by main.tf, vpc.tf, etc.
provider "aws" {
  region = var.aws_region # This should be us-east-1

  assume_role {
    role_arn     = "arn:aws:iam::${var.target_account_id}:role/${var.target_role_name}"
    session_name = "TerrJenkSession-ENG"
  }
}

# Provider for the AUTOMATION account
# This will be used for inspector.tf and inspector_iam_policy.tf
provider "aws" {
  alias  = "automation"
  region = "us-east-1" 
}