variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the subscription of the cloud connector (ARM_SUBSCRIPTION_ID)."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the resource group and the storage account."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Prefix for resource names. A random suffix is added to keep names unique."
  type        = string
  default     = "sgsandbox"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,15}$", var.name_prefix))
    error_message = "name_prefix must be 3-16 lowercase letters or digits, starting with a letter."
  }
}

variable "container_name" {
  description = "Name of the private blob container."
  type        = string
  default     = "data"

  validation {
    condition     = can(regex("^[a-z0-9](-?[a-z0-9])+$", var.container_name)) && length(var.container_name) <= 63
    error_message = "container_name must be 3-63 lowercase letters, digits or single hyphens."
  }
}
