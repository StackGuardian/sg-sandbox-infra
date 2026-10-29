# Shows a workflow consuming a secret from the StackGuardian vault. The token
# arrives as a sensitive variable. Only a short fingerprint of it ever leaves
# this stack, so you can tell which token is configured without seeing it.

locals {
  tags = {
    environment = var.environment
    stack       = "secrets-demo"
    owner       = "platform-team"
    managed_by  = "stackguardian"
  }

  # First 8 hex characters of the token's SHA-256: enough to tell tokens apart,
  # not enough to recover one.
  token_fingerprint = nonsensitive(substr(sha256(var.api_token), 0, 8))
}

# Release guard: during a change freeze every plan fails before anything moves.
resource "terraform_data" "change_guard" {
  input = {
    stack       = "secrets-demo"
    environment = var.environment
  }

  lifecycle {
    precondition {
      condition     = !var.change_freeze
      error_message = "Change freeze is active for ${var.environment}-secrets-demo. Unset change_freeze to deploy."
    }
  }
}

resource "terraform_data" "api_client" {
  input = {
    name              = "${var.environment}-deploy-api-client"
    environment       = var.environment
    auth              = "bearer-token"
    token_source      = "stackguardian-vault"
    token_fingerprint = local.token_fingerprint
    public_ingress    = false
    tags              = local.tags
  }
}
