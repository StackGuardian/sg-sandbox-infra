# A resource group and a locked-down StorageV2 account with blob versioning
# and one private container.

locals {
  tags = {
    managed-by       = "stackguardian-sandbox"
    sandbox-template = "azure-storage-account"
  }
}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}-${random_string.suffix.result}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "this" {
  name                = "${var.name_prefix}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  tags = local.tags
}

resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
