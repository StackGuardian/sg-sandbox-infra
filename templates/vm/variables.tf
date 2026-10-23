variable "name" {
  description = "Name of the virtual machine."
  type        = string
  default     = "demo-vm"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.name))
    error_message = "name must be 3-40 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "region" {
  description = "AWS region the VM would run in."
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.small"
}

variable "disk_size_gb" {
  description = "Size of the root disk in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 8 && var.disk_size_gb <= 500
    error_message = "disk_size_gb must be between 8 and 500."
  }
}

variable "allowed_cidrs" {
  description = "CIDR ranges allowed to reach the VM on port 443. Including 0.0.0.0/0 makes it public."
  type        = list(string)
  default     = ["10.0.0.0/8"]

  validation {
    condition     = alltrue([for c in var.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Every entry in allowed_cidrs must be a valid CIDR range."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    environment = "sandbox"
    managed_by  = "stackguardian"
  }
}
