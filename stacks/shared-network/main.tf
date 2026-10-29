# Shared network for production: one shared services VPC, a transit gateway
# that the regional networks attach to, and the CIDR block reserved for each
# region. Regional network workflows read the outputs of this stack.

locals {
  name = "${var.environment}-shared"

  tags = {
    environment = var.environment
    stack       = "shared-network"
    owner       = "platform-team"
    managed_by  = "stackguardian"
  }

  # Mock IDs, stable across runs, shaped like real ones.
  vpc_id             = "vpc-${substr(sha256("${local.name}-vpc-${var.shared_vpc_cidr}"), 0, 17)}"
  transit_gateway_id = "tgw-${substr(sha256("${local.name}-tgw"), 0, 17)}"

  regional_cidrs = {
    "eu-central-1" = var.cidr_eu_central_1
    "us-east-2"    = var.cidr_us_east_2
  }

  runbook_path = "${path.module}/.sg/runbook.md"
}

# Release guard: during a change freeze every plan fails before anything moves.
resource "terraform_data" "change_guard" {
  input = {
    stack       = "shared-network"
    environment = var.environment
  }

  lifecycle {
    precondition {
      condition     = !var.change_freeze
      error_message = "Change freeze is active for ${var.environment}-shared-network. Unset change_freeze to deploy."
    }
  }
}

resource "terraform_data" "shared_vpc" {
  input = {
    name                 = "${local.name}-vpc"
    vpc_id               = local.vpc_id
    environment          = var.environment
    region               = var.home_region
    cidr_block           = var.shared_vpc_cidr
    enable_dns_hostnames = true
    public_ingress       = false
    tags                 = local.tags
  }

  triggers_replace = [var.shared_vpc_cidr]
}

resource "terraform_data" "transit_gateway" {
  input = {
    name                = "${local.name}-tgw"
    transit_gateway_id  = local.transit_gateway_id
    environment         = var.environment
    region              = var.home_region
    amazon_side_asn     = 64512
    default_route_table = "disabled"
    tags                = local.tags
  }
}

resource "terraform_data" "shared_vpc_attachment" {
  input = {
    name               = "${local.name}-vpc-attachment"
    environment        = var.environment
    vpc_id             = terraform_data.shared_vpc.output.vpc_id
    transit_gateway_id = terraform_data.transit_gateway.output.transit_gateway_id
  }
}

# One reserved block per region. Changing a block replaces the allocation.
resource "terraform_data" "regional_allocation" {
  for_each = local.regional_cidrs

  input = {
    name               = "${var.environment}-${each.key}"
    environment        = var.environment
    region             = each.key
    cidr_block         = each.value
    transit_gateway_id = terraform_data.transit_gateway.output.transit_gateway_id
  }

  triggers_replace = [each.value]
}

# Network runbook rendered from the live configuration, into the run's working
# directory. A fresh runner does not have the file, so a drift check reports it
# as changed outside OpenTofu.
resource "local_file" "runbook" {
  filename        = local.runbook_path
  file_permission = "0644"
  content = templatefile("${path.module}/templates/runbook.md.tftpl", {
    environment        = var.environment
    home_region        = var.home_region
    vpc_id             = terraform_data.shared_vpc.output.vpc_id
    vpc_cidr           = terraform_data.shared_vpc.output.cidr_block
    transit_gateway_id = terraform_data.transit_gateway.output.transit_gateway_id
    regions            = { for region, a in terraform_data.regional_allocation : region => a.output.cidr_block }
  })
}
