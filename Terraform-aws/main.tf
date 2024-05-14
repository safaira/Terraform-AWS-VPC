terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
    required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}



resource "aws_instance" "ec2_instnce" {   # always write '_' instead of '-'
    for_each = toset ( ["t-1", "t-2"] )            # use local.xxx to take the value from locals.
    ami = "ami-0287a05f0ef0e9d9a"
    instance_type = "t2.micro"
    tags = {
      Name = each.key
    }
}

