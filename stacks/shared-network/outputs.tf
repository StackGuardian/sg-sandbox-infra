output "vpc_id" {
  description = "ID of the shared services VPC."
  value       = terraform_data.shared_vpc.output.vpc_id
}

output "transit_gateway_id" {
  description = "ID of the transit gateway the regional networks attach to."
  value       = terraform_data.transit_gateway.output.transit_gateway_id
}

output "cidr_eu_central_1" {
  description = "CIDR block reserved for the eu-central-1 network."
  value       = terraform_data.regional_allocation["eu-central-1"].output.cidr_block
}

output "cidr_us_east_2" {
  description = "CIDR block reserved for the us-east-2 network."
  value       = terraform_data.regional_allocation["us-east-2"].output.cidr_block
}

output "runbook_path" {
  description = "Where the network runbook was rendered."
  value       = local_file.runbook.filename
}
