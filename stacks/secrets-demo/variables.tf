variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "api_token" {
  description = "Token for the deployment API client. On StackGuardian it comes from a vault secret through the TF_VAR_api_token environment variable. Never stored in an output."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.api_token)) >= 8
    error_message = "api_token must be at least 8 characters. Check that the workflow's TF_VAR_api_token points at an existing secret."
  }
}

variable "change_freeze" {
  description = "Set to true during a change freeze. Any plan against this stack then fails."
  type        = bool
  default     = false
}
