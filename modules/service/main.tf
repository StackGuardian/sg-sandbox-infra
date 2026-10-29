# Mock containerized service: load balancer, service, database and autoscaling,
# plus a post-deploy rollout check. Infrastructure objects are terraform_data;
# the rollout check is a null_resource, so policies that watch for destroyed
# infrastructure (terraform_data deletes) don't fire on routine re-checks.

resource "terraform_data" "load_balancer" {
  input = {
    name           = "${var.name}-alb"
    environment    = var.environment
    scheme         = var.public_ingress ? "internet-facing" : "internal"
    listener_port  = 443
    tls_policy     = "TLS13-1-2-2021-06"
    public_ingress = var.public_ingress
    ingress_cidrs  = var.public_ingress ? ["0.0.0.0/0"] : var.internal_cidrs
    tags           = var.tags
  }
}

resource "terraform_data" "database" {
  input = {
    name                = "${var.name}-db"
    environment         = var.environment
    engine              = var.db_engine
    engine_version      = var.db_engine_version
    instance_class      = var.db_instance_class
    multi_az            = var.db_multi_az
    encrypted           = true
    backup_retention    = 14
    deletion_protection = true
    tags                = var.tags
  }

  # A major engine upgrade is a replacement, not an in-place change.
  triggers_replace = [var.db_engine, var.db_engine_version]
}

resource "terraform_data" "service" {
  input = {
    name          = var.name
    environment   = var.environment
    image         = "registry.example.com/${var.name}:${var.image_tag}"
    image_tag     = var.image_tag
    replica_count = var.replica_count
    cpu           = var.cpu
    memory        = var.memory
    target_group  = terraform_data.load_balancer.output.name
    database      = terraform_data.database.output.name
    tags          = var.tags
  }
}

resource "terraform_data" "autoscaling" {
  input = {
    name                 = "${var.name}-autoscaling"
    environment          = var.environment
    service              = terraform_data.service.output.name
    min_capacity         = var.replica_count
    max_capacity         = var.autoscaling_max
    target_cpu_percent   = 60
    scale_in_cooldown_s  = 300
    scale_out_cooldown_s = 60
  }
}

# Runs after every rollout and fails the apply when too few targets are healthy.
resource "null_resource" "rollout_check" {
  triggers = {
    image_tag           = var.image_tag
    replica_count       = var.replica_count
    healthy_targets     = var.healthy_targets
    min_healthy_targets = var.min_healthy_targets
  }

  provisioner "local-exec" {
    command = "sh '${var.rollout_check_script}'"
    environment = {
      SERVICE             = var.name
      HEALTHY_TARGETS     = var.healthy_targets
      MIN_HEALTHY_TARGETS = var.min_healthy_targets
    }
  }

  depends_on = [terraform_data.service, terraform_data.autoscaling]
}
