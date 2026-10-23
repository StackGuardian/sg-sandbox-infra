# Mock network. Every object is a terraform_data resource, so nothing is created
# in a cloud account, but plans and state look like a real VPC rollout.
#
# Conventions used across this repo:
# - Infrastructure objects are terraform_data. Attributes a policy may inspect
#   live in `input`; changes to them are in-place updates.
# - Attributes that a real provider cannot change in place go in
#   `triggers_replace`, so changing them shows up as a replace (delete + create).

locals {
  azs = { for idx, az in var.availability_zones : az => idx }
}

resource "terraform_data" "vpc" {
  input = {
    name                 = "${var.name}-vpc"
    environment          = var.environment
    region               = var.region
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    tags                 = var.tags
  }

  triggers_replace = [var.vpc_cidr]
}

resource "terraform_data" "public_subnet" {
  for_each = local.azs

  input = {
    name                    = "${var.name}-public-${each.key}"
    environment             = var.environment
    vpc                     = terraform_data.vpc.output.name
    availability_zone       = "${var.region}${each.key}"
    cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value)
    map_public_ip_on_launch = true
    tier                    = "public"
  }

  triggers_replace = [var.vpc_cidr]
}

resource "terraform_data" "private_subnet" {
  for_each = local.azs

  input = {
    name                    = "${var.name}-private-${each.key}"
    environment             = var.environment
    vpc                     = terraform_data.vpc.output.name
    availability_zone       = "${var.region}${each.key}"
    cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value + 8)
    map_public_ip_on_launch = false
    tier                    = "private"
  }

  triggers_replace = [var.vpc_cidr]
}

resource "terraform_data" "nat_gateway" {
  count = var.nat_gateway_count

  input = {
    name        = "${var.name}-nat-${var.availability_zones[count.index % length(var.availability_zones)]}"
    environment = var.environment
    subnet      = terraform_data.public_subnet[var.availability_zones[count.index % length(var.availability_zones)]].output.name
  }
}

resource "terraform_data" "private_route_table" {
  for_each = local.azs

  input = {
    name        = "${var.name}-private-rt-${each.key}"
    environment = var.environment
    subnet      = terraform_data.private_subnet[each.key].output.name
    default_route = var.nat_gateway_count > 0 ? (
      terraform_data.nat_gateway[each.value % var.nat_gateway_count].output.name
    ) : "none"
  }
}

resource "terraform_data" "default_security_group" {
  input = {
    name           = "${var.name}-default-sg"
    environment    = var.environment
    vpc            = terraform_data.vpc.output.name
    ingress_cidrs  = [var.vpc_cidr]
    public_ingress = false
  }
}

resource "terraform_data" "flow_logs" {
  input = {
    name           = "${var.name}-flow-logs"
    environment    = var.environment
    vpc            = terraform_data.vpc.output.name
    traffic_type   = "ALL"
    retention_days = var.flow_logs_retention_days
    encrypted      = true
  }
}
