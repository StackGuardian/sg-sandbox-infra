output "instance_name" {
  description = "Name of the mock VM."
  value       = terraform_data.instance.output.name
}

output "instance_type" {
  description = "Instance type of the mock VM."
  value       = terraform_data.instance.output.instance_type
}

output "public_ingress" {
  description = "Whether the security group allows 0.0.0.0/0."
  value       = terraform_data.security_group.output.public_ingress
}
