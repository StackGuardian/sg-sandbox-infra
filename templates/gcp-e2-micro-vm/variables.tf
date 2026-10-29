variable "project_id" {
  description = "ID of the Google Cloud project to create the VM in."
  type        = string
}

variable "region" {
  description = "Google Cloud region for the network."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone for the VM. It must be in the region. Leave empty to use the region's first available zone (not every region has an \"-a\" zone)."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Prefix for resource names. A random suffix is added to keep names unique."
  type        = string
  default     = "sgsandbox"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-40 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "machine_type" {
  description = "Machine type. e2-micro is in the Google Cloud free tier in some US regions."
  type        = string
  default     = "e2-micro"
}

variable "external_ip_enabled" {
  description = "Give the VM an ephemeral external IP."
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR ranges allowed to reach the VM on port 22. Empty means no inbound traffic at all."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_ssh_cidrs : can(cidrhost(c, 0))])
    error_message = "Every entry in allowed_ssh_cidrs must be a valid CIDR range."
  }
}
