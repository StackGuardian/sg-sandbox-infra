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

variable "use_default_vpc" {
  description = "Deploy into the account's default VPC instead of creating a new one. Use this when the region is at its VPC quota (5 by default) and the deploy fails with \"maximum number of VPCs\". The region must still have its default VPC."
  type        = bool
  default     = false
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
  description = "CIDR range allowed to reach the Kubernetes API (6443). The default is open to the internet; restrict it to your own range. Runs that use the kubeconfig, such as a Helm release, must come from inside it."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_cidr, 0))
    error_message = "allowed_cidr must be a valid CIDR range."
  }
}

variable "kubeconfig_wait_seconds" {
  description = "How long the first apply waits for k3s to publish its kubeconfig."
  type        = number
  default     = 300

  validation {
    condition     = var.kubeconfig_wait_seconds >= 60 && var.kubeconfig_wait_seconds <= 900
    error_message = "kubeconfig_wait_seconds must be between 60 and 900."
  }
}
