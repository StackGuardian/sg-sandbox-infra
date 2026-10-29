variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "home_region" {
  description = "Region that hosts the shared VPC and the transit gateway."
  type        = string
  default     = "eu-central-1"
}

variable "shared_vpc_cidr" {
  description = "CIDR block of the shared services VPC. Changing it replaces the VPC."
  type        = string
  default     = "10.30.0.0/16"

  validation {
    condition     = can(cidrhost(var.shared_vpc_cidr, 0))
    error_message = "shared_vpc_cidr must be a valid IPv4 CIDR block, e.g. 10.30.0.0/16."
  }
}

variable "cidr_eu_central_1" {
  description = "CIDR block reserved for the eu-central-1 regional network."
  type        = string
  default     = "10.50.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_eu_central_1, 0))
    error_message = "cidr_eu_central_1 must be a valid IPv4 CIDR block."
  }
}

variable "cidr_us_east_2" {
  description = "CIDR block reserved for the us-east-2 regional network."
  type        = string
  default     = "10.60.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_us_east_2, 0))
    error_message = "cidr_us_east_2 must be a valid IPv4 CIDR block."
  }
}

variable "change_freeze" {
  description = "Set to true during a change freeze. Any plan against this stack then fails."
  type        = bool
  default     = false
}
