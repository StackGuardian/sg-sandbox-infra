variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "demo-aks"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be 3-40 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "location" {
  description = "Azure region the cluster would run in."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group that would hold the cluster."
  type        = string
  default     = "rg-demo-aks"
}

variable "kubernetes_version" {
  description = "Kubernetes control plane version."
  type        = string
  default     = "1.31"

  validation {
    condition     = contains(["1.29", "1.30", "1.31"], var.kubernetes_version)
    error_message = "kubernetes_version must be 1.29, 1.30 or 1.31."
  }
}

variable "node_vm_size" {
  description = "VM size for the default node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "node_count must be between 1 and 10."
  }
}

variable "api_server_public_access" {
  description = "Expose the Kubernetes API server to the internet."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    environment = "sandbox"
    managed_by  = "stackguardian"
  }
}
