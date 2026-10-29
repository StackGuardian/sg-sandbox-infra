output "vpc_name" {
  description = "Name of the production VPC."
  value       = module.network.vpc_name
}

output "vpc_cidr" {
  description = "CIDR block of the production VPC."
  value       = module.network.vpc_cidr
}

output "public_subnets" {
  description = "Public subnet CIDR blocks by AZ."
  value       = module.network.public_subnets
}

output "private_subnets" {
  description = "Private subnet CIDR blocks by AZ."
  value       = module.network.private_subnets
}

output "nat_gateways" {
  description = "NAT gateway names."
  value       = module.network.nat_gateways
}

output "region" {
  description = "Region the network is planned for."
  value       = var.region
}

output "shared_vpc_id" {
  description = "Shared services VPC this network is attached to, or empty when standalone."
  value       = var.shared_vpc_id
}
