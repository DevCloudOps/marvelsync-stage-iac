terraform {
  required_version = ">= 1.5.7"
  # backend "s3" {
  #   bucket         = "jarwiz-medexpert-terraform"
  #   key            = "terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   # dynamodb_table = "jarwiz-medexpert-terraform"
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