variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "demo-eks"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be 3-40 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "region" {
  description = "AWS region the cluster would run in."
  type        = string
  default     = "eu-central-1"
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

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group."
  type        = string
  default     = "t3.medium"
}

variable "node_count" {
  description = "Desired number of nodes in the managed node group."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "node_count must be between 1 and 10."
  }
}

variable "node_count_max" {
  description = "Upper bound for node group autoscaling. Added in revision 2. Must be at least node_count."
  type        = number
  default     = 4

  validation {
    condition     = var.node_count_max >= 1 && var.node_count_max <= 20
    error_message = "node_count_max must be between 1 and 20."
  }
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint to the internet."
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
