# Real template: creates resources in Google Cloud. State is managed by
# StackGuardian, so there is no backend block.
terraform {
  required_version = ">= 1.8"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

# Credentials come from the GCP cloud connector.
provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = {
    managed-by       = "stackguardian-sandbox"
    sandbox-template = "gcp-gcs-bucket"
  }
}
