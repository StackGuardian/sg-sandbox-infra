# Real template: creates a VPC and one EC2 instance in the AWS account of the
# workflow's cloud connector. State is managed by StackGuardian, so there is
# no backend block.
terraform {
  required_version = ">= 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed-by       = "stackguardian-sandbox"
      sandbox-template = "aws-ec2-vm"
    }
  }
}
