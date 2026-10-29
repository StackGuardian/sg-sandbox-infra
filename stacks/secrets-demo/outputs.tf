output "configured" {
  description = "True when an API token was provided."
  value       = terraform_data.api_client.output.token_fingerprint != ""
}

output "token_fingerprint" {
  description = "First 8 hex characters of the token's SHA-256. Identifies the token without revealing it."
  value       = terraform_data.api_client.output.token_fingerprint
}
