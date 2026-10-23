variable "name" {
  description = "Name prefix for every network object."
  type        = string
}

variable "environment" {
  description = "Environment the network belongs to, e.g. prod or staging."
  type        = string
}

variable "region" {
  description = "Region the network is planned for."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC. Changing it replaces the VPC and every subnet."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, e.g. 10.40.0.0/16."
  }
}

variable "availability_zones" {
  description = "Availability zone suffixes to spread subnets across."
  type        = list(string)
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways. One per AZ is recommended for production."
  type        = number

  validation {
    condition     = var.nat_gateway_count >= 0
    error_message = "nat_gateway_count cannot be negative."
  }
}

variable "flow_logs_retention_days" {
  description = "How long VPC flow logs are kept."
  type        = number
}

variable "tags" {
  description = "Tags applied to every object."
  type        = map(string)
  default     = {}
}
