# Mock of an AKS cluster: resource group, cluster with its default node pool,
# and a log analytics workspace. Each terraform_data carries the attributes a
# real resource would have, so policies can inspect input.*.

resource "terraform_data" "resource_group" {
  input = {
    kind           = "azurerm_resource_group"
    name           = var.resource_group_name
    location       = var.location
    public_ingress = false
    tags           = var.tags
  }
}

resource "terraform_data" "log_analytics" {
  input = {
    kind           = "azurerm_log_analytics_workspace"
    name           = "${var.cluster_name}-logs"
    resource_group = terraform_data.resource_group.output.name
    retention_days = 30
    public_ingress = false
    tags           = var.tags
  }
}

resource "terraform_data" "cluster" {
  input = {
    kind               = "azurerm_kubernetes_cluster"
    name               = var.cluster_name
    resource_group     = terraform_data.resource_group.output.name
    location           = var.location
    kubernetes_version = var.kubernetes_version
    node_vm_size       = var.node_vm_size
    node_count         = var.node_count
    log_workspace      = terraform_data.log_analytics.output.name
    public_ingress     = var.api_server_public_access
    encrypted          = true
    tags               = var.tags
  }
}
