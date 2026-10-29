variable "region" {
  description = "AWS region for the VPC and the instance."
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "Name prefix for every resource. A random suffix is added."
  type        = string
  default     = "sg-sandbox-vm"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name))
    error_message = "name must be 2-31 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "vpc_cidr" {
  description = "CIDR range of the VPC. The public subnet uses the first /24 of it."
  type        = string
  default     = "10.60.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "vpc_cidr must be a valid CIDR range of /24 or larger."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size_gb" {
  description = "Size of the encrypted gp3 root volume in GiB."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size_gb >= 8 && var.root_volume_size_gb <= 100
    error_message = "root_volume_size_gb must be between 8 and 100."
  }
}

variable "allowed_ingress_cidrs" {
  description = "CIDR ranges allowed to reach the instance on SSH (port 22). Empty means no inbound access; use Session Manager instead."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_ingress_cidrs : can(cidrhost(c, 0))])
    error_message = "Every entry in allowed_ingress_cidrs must be a valid CIDR range."
  }
}
