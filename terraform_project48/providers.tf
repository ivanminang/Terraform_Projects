
# Terraform Block (Define the required provider, his source and the provider version)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
# Provider Block (Define the aws Provider and the region)
provider "aws" {
  region = var.aws_region
}
# Resources Block (configure all the resources)