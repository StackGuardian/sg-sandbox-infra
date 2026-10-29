variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the subscription of the cloud connector (ARM_SUBSCRIPTION_ID)."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for every resource."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Prefix for resource names. A random suffix is added to keep names unique."
  type        = string
  default     = "sgsandbox"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-20 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B1s"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GiB."
  type        = number
  default     = 30

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 256
    error_message = "os_disk_size_gb must be between 30 and 256."
  }
}

variable "public_ip_enabled" {
  description = "Give the VM a Standard SKU static public IP."
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

variable "auto_shutdown_enabled" {
  description = "Stop the VM every day at auto_shutdown_time (UTC)."
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Daily shutdown time in UTC, as HHMM."
  type        = string
  default     = "1900"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3])[0-5][0-9]$", var.auto_shutdown_time))
    error_message = "auto_shutdown_time must be HHMM in 24-hour time, e.g. 1900."
  }
}
