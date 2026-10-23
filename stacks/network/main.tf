locals {
  name = "${var.environment}-core"

  tags = {
    environment = var.environment
    stack       = "network"
    owner       = "platform-team"
    managed_by  = "stackguardian"
  }
}

# Release guard: during a change freeze every plan fails before anything moves.
resource "terraform_data" "change_guard" {
  input = {
    stack       = "network"
    environment = var.environment
  }

  lifecycle {
    precondition {
      condition     = !var.change_freeze
      error_message = "Change freeze is active for ${var.environment}-network. Unset change_freeze to deploy."
    }
  }
}

module "network" {
  source = "../../modules/network"

  name                     = local.name
  environment              = var.environment
  region                   = var.region
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  nat_gateway_count        = var.nat_gateway_count
  flow_logs_retention_days = var.flow_logs_retention_days
  tags                     = local.tags
}
