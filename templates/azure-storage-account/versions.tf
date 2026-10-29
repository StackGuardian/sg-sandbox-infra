# Real template: creates resources in Azure. State is managed by StackGuardian,
# so there is no backend block.
terraform {
  required_version = ">= 1.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

# Credentials come from the Azure cloud connector. With subscription_id left
# null, the provider reads ARM_SUBSCRIPTION_ID from the environment.
provider "azurerm" {
  features {}

  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}
