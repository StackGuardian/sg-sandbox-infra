variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "alert_threshold_p99_ms" {
  description = "p99 latency (ms) that pages the on-call engineer."
  type        = number
  default     = 750
}

variable "error_rate_threshold_percent" {
  description = "5xx error rate (%) that pages the on-call engineer."
  type        = number
  default     = 2
}

variable "backup_retention_days" {
  description = "Days to keep nightly backups."
  type        = number
  default     = 35
}

variable "public_ingress" {
  description = "Expose the status endpoint to the internet instead of the internal network."
  type        = bool
  default     = false
}

variable "drift_probe" {
  description = "Where the on-call runbook is rendered: \"ephemeral\" (the run's working directory, gone after every run) or \"artifacts\" (runbook_artifacts_path, kept between runs)."
  type        = string
  default     = "ephemeral"

  validation {
    condition     = contains(["ephemeral", "artifacts"], var.drift_probe)
    error_message = "drift_probe must be \"ephemeral\" or \"artifacts\"."
  }
}

variable "runbook_artifacts_path" {
  description = "Runbook path when drift_probe is \"artifacts\"."
  type        = string
  default     = "/mnt/sg_workspace/artifacts/ops/runbook.md"
}

variable "simulate_manual_edit" {
  description = "Edit the rendered runbook outside OpenTofu, the way a hand-made hotfix would. Used to demonstrate drift detection."
  type        = bool
  default     = false
}

variable "change_freeze" {
  description = "Set to true during a change freeze. Any plan against this stack then fails."
  type        = bool
  default     = false
}
