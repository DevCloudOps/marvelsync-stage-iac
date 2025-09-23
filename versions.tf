terraform {
  required_version = ">= 1.5.7"
  # backend "s3" {
  #   bucket         = "jarwiz-iac-stage"
  #   key            = "terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   # dynamodb_table = "jarwiz-iac-stage"
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}