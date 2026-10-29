variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Region the network is planned for."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block of the production VPC. Changing it replaces the VPC and all subnets."
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "Availability zone suffixes."
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways."
  type        = number
  default     = 3
}

variable "flow_logs_retention_days" {
  description = "VPC flow log retention."
  type        = number
  default     = 90
}

variable "change_freeze" {
  description = "Set to true during a change freeze. Any plan against this stack then fails."
  type        = bool
  default     = false
}

variable "shared_vpc_id" {
  description = "ID of the shared services VPC to attach to, usually the vpc_id output of the shared-network workflow. Empty means a standalone network."
  type        = string
  default     = ""
}
