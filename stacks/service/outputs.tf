output "service_name" {
  description = "Name of the service."
  value       = module.checkout_api.service_name
}

output "image" {
  description = "Image currently deployed."
  value       = module.checkout_api.image
}

output "database" {
  description = "Database name and engine version."
  value       = module.checkout_api.database
}
