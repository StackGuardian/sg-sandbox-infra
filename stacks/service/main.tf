locals {
  tags = {
    environment = var.environment
    stack       = "service"
    service     = "checkout-api"
    owner       = "payments-team"
    managed_by  = "stackguardian"
  }
}

# Release guard: during a change freeze every plan fails before anything moves.
resource "terraform_data" "change_guard" {
  input = {
    stack       = "service"
    environment = var.environment
  }

  lifecycle {
    precondition {
      condition     = !var.change_freeze
      error_message = "Change freeze is active for ${var.environment}-checkout-api. Unset change_freeze to deploy."
    }
  }
}

module "checkout_api" {
  source = "../../modules/service"

  name                 = "checkout-api"
  environment          = var.environment
  image_tag            = var.image_tag
  replica_count        = var.replica_count
  cpu                  = 512
  memory               = 1024
  autoscaling_max      = 12
  db_engine            = "postgres"
  db_engine_version    = var.db_engine_version
  db_instance_class    = var.db_instance_class
  db_multi_az          = true
  healthy_targets      = var.healthy_targets
  min_healthy_targets  = var.min_healthy_targets
  public_ingress       = var.public_ingress
  rollout_check_script = "${path.module}/../../scripts/verify-rollout.sh"
  tags                 = local.tags
}
