terraform {
  backend "s3" {
    bucket = "roboshop-aws-terraform"
    key    = "ecom-multi-cloud-terraform/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.62.0"
    }
  }
}

provider "aws" {
  # Configuration options
}
