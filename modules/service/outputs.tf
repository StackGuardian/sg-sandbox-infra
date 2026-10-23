output "service_name" {
  description = "Name of the service."
  value       = terraform_data.service.output.name
}

output "image" {
  description = "Image currently deployed."
  value       = terraform_data.service.output.image
}

output "database" {
  description = "Database name and engine version."
  value = {
    name           = terraform_data.database.output.name
    engine         = terraform_data.database.output.engine
    engine_version = terraform_data.database.output.engine_version
  }
}
