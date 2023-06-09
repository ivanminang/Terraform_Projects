
# Terraform Block (Define the required provider, his source and the provider version)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  # Configure remote state management
  backend "s3" {
    bucket = "tfstatefile-remote-storage"
    key    = "dev/terraform.tfstate"
    region = "us-west-2"

    # Configure state file locking
    dynamodb_table = "terraform-state-locking-table"
  }
}
# Provider Block (Define the aws Provider and the region)
provider "aws" {
  region = var.aws_region
}
# Resources Block (configure all the resources)