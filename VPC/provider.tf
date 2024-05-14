terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.16"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}