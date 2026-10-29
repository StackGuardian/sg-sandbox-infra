# Real template: creates a VPC and a single-node k3s cluster on EC2 in the AWS
# account of the workflow's cloud connector. State is managed by
# StackGuardian, so there is no backend block.
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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed-by       = "stackguardian-sandbox"
      sandbox-template = "aws-k3s"
    }
  }
}
