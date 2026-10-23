# Temporary: switches that let one workflow exercise every platform scenario
# (failed apply, drift). Removed once the scenarios move to their own stacks.

variable "healthy_targets" {
  description = "Healthy gateway targets reported after apply."
  type        = number
  default     = 3
}

variable "min_healthy_targets" {
  description = "Minimum healthy targets for a good rollout."
  type        = number
  default     = 2
}

variable "render_runbook" {
  description = "Render the network runbook to disk."
  type        = bool
  default     = false
}

variable "drift_probe" {
  description = "Where the runbook is rendered: \"ephemeral\" (the run's working directory) or \"artifacts\" (runbook_artifacts_path, kept between runs)."
  type        = string
  default     = "ephemeral"

  validation {
    condition     = contains(["ephemeral", "artifacts"], var.drift_probe)
    error_message = "drift_probe must be \"ephemeral\" or \"artifacts\"."
  }
}

variable "runbook_artifacts_path" {
  description = "Runbook location when drift_probe is \"artifacts\"."
  type        = string
  default     = "/mnt/sg_workspace/artifacts/network/runbook.md"
}

variable "simulate_manual_edit" {
  description = "Overwrite the rendered runbook outside Terraform, the way a manual hotfix would."
  type        = bool
  default     = false
}

resource "null_resource" "verify_gateway" {
  triggers = {
    nat_gateways        = join(",", module.network.nat_gateways)
    healthy_targets     = var.healthy_targets
    min_healthy_targets = var.min_healthy_targets
  }

  provisioner "local-exec" {
    command = "sh ${path.module}/../../scripts/verify-rollout.sh"
    environment = {
      SERVICE             = "${var.environment}-nat-gateways"
      HEALTHY_TARGETS     = var.healthy_targets
      MIN_HEALTHY_TARGETS = var.min_healthy_targets
    }
  }
}

resource "local_file" "runbook" {
  count = var.render_runbook ? 1 : 0

  filename = var.drift_probe == "artifacts" ? var.runbook_artifacts_path : "${path.module}/.sg/runbook.md"
  content  = "# ${var.environment} network runbook\n\nVPC: ${module.network.vpc_cidr}\nNAT gateways: ${var.nat_gateway_count}\n"
}

resource "null_resource" "manual_edit" {
  count = var.render_runbook && var.simulate_manual_edit ? 1 : 0

  triggers = {
    run = timestamp()
  }

  provisioner "local-exec" {
    command = "printf '%s\\n' '# edited by hand during an incident' > '${local_file.runbook[0].filename}'"
  }
}
