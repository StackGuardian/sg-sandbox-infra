locals {
  tags = {
    environment = var.environment
    stack       = "ops"
    owner       = "sre-team"
    managed_by  = "stackguardian"
  }

  runbook_path = var.drift_probe == "artifacts" ? var.runbook_artifacts_path : "${path.module}/.sg/runbook.md"
}

# Release guard: during a change freeze every plan fails before anything moves.
resource "terraform_data" "change_guard" {
  input = {
    stack       = "ops"
    environment = var.environment
  }

  lifecycle {
    precondition {
      condition     = !var.change_freeze
      error_message = "Change freeze is active for ${var.environment}-ops. Unset change_freeze to deploy."
    }
  }
}

resource "terraform_data" "oncall_schedule" {
  input = {
    name        = "${var.environment}-primary"
    environment = var.environment
    rotation    = "weekly"
    handoff     = "MON 09:00 America/New_York"
    escalation  = ["primary", "secondary", "engineering-manager"]
    tags        = local.tags
  }
}

resource "terraform_data" "alert_rule" {
  for_each = {
    checkout-api-latency-p99 = { metric = "http.server.duration.p99", threshold = var.alert_threshold_p99_ms, unit = "ms" }
    checkout-api-error-rate  = { metric = "http.server.errors.5xx.rate", threshold = var.error_rate_threshold_percent, unit = "percent" }
    nat-gateway-packet-drops = { metric = "nat.packets.dropped", threshold = 1000, unit = "count" }
  }

  input = {
    name        = each.key
    environment = var.environment
    metric      = each.value.metric
    threshold   = each.value.threshold
    unit        = each.value.unit
    window      = "5m"
    notify      = terraform_data.oncall_schedule.output.name
  }
}

resource "terraform_data" "backup_policy" {
  input = {
    name           = "${var.environment}-nightly"
    environment    = var.environment
    schedule       = "cron(0 3 * * ? *)"
    retention_days = var.backup_retention_days
    targets        = ["checkout-api-db"]
    encrypted      = true
    cross_region   = true
  }
}

resource "terraform_data" "status_endpoint" {
  input = {
    name           = "${var.environment}-status"
    environment    = var.environment
    path           = "/healthz/summary"
    public_ingress = var.public_ingress
    ingress_cidrs  = var.public_ingress ? ["0.0.0.0/0"] : ["10.40.0.0/16"]
    tags           = local.tags
  }
}

# On-call runbook rendered from the live configuration. If someone edits or
# removes it outside OpenTofu, the next drift check reports it.
resource "local_file" "runbook" {
  filename        = local.runbook_path
  file_permission = "0644"
  content = templatefile("${path.module}/templates/runbook.md.tftpl", {
    environment    = var.environment
    schedule       = terraform_data.oncall_schedule.output.name
    handoff        = terraform_data.oncall_schedule.output.handoff
    alerts         = { for name, rule in terraform_data.alert_rule : name => "${rule.output.threshold} ${rule.output.unit}" }
    backup         = terraform_data.backup_policy.output.schedule
    retention_days = terraform_data.backup_policy.output.retention_days
    status_path    = terraform_data.status_endpoint.output.path
  })
}

# Drift demonstration: edits the runbook after OpenTofu wrote it.
resource "null_resource" "manual_edit" {
  count = var.simulate_manual_edit ? 1 : 0

  triggers = {
    run = timestamp()
  }

  provisioner "local-exec" {
    command = "printf '%s\\n' '# Edited by hand during an incident. Not in version control.' > '${local_file.runbook.filename}'"
  }
}
