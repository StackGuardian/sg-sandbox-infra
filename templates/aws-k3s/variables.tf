variable "region" {
  description = "AWS region for the VPC and the k3s node."
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "Name prefix for every resource. A random suffix is added."
  type        = string
  default     = "sandbox-k3s"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name)) && !startswith(var.name, "sg-")
    error_message = "name must be 2-31 lowercase letters, digits or hyphens, starting with a letter and not with \"sg-\" (AWS reserves it for security group names)."
  }
}

variable "vpc_cidr" {
  description = "CIDR range of the VPC. The public subnet uses the first /24 of it."
  type        = string
  default     = "10.61.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "vpc_cidr must be a valid CIDR range of /24 or larger."
  }
}

variable "instance_type" {
  description = "EC2 instance type. k3s needs about 2 GB of memory."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size_gb" {
  description = "Size of the encrypted gp3 root volume in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size_gb >= 10 && var.root_volume_size_gb <= 100
    error_message = "root_volume_size_gb must be between 10 and 100."
  }
}

variable "allowed_cidr" {
  description = "CIDR range allowed to reach SSH (22) and the Kubernetes API (6443). The default is open to the internet; restrict it to your own range. The runner that applies this template must be inside it, because it connects over SSH."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_cidr, 0))
    error_message = "allowed_cidr must be a valid CIDR range."
  }
}
