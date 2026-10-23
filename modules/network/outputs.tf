output "vpc_name" {
  description = "Name of the VPC."
  value       = terraform_data.vpc.output.name
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = terraform_data.vpc.output.cidr_block
}

output "public_subnets" {
  description = "Public subnet CIDR blocks by AZ."
  value       = { for az, s in terraform_data.public_subnet : az => s.output.cidr_block }
}

output "private_subnets" {
  description = "Private subnet CIDR blocks by AZ."
  value       = { for az, s in terraform_data.private_subnet : az => s.output.cidr_block }
}

output "nat_gateways" {
  description = "Names of the NAT gateways."
  value       = [for n in terraform_data.nat_gateway : n.output.name]
}
