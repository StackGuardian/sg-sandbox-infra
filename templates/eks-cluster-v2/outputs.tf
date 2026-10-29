output "cluster_name" {
  description = "Name of the mock EKS cluster."
  value       = terraform_data.cluster.output.name
}

output "cluster_endpoint" {
  description = "Mock API endpoint. The .invalid domain never resolves."
  value       = "https://${terraform_data.cluster.output.name}.eks.${var.region}.example.invalid"
}

output "node_group" {
  description = "Node group name, instance type, size and autoscaling bounds."
  value       = "${terraform_data.node_group.output.name} (${terraform_data.node_group.output.instance_type} x ${terraform_data.node_group.output.desired_size}, max ${terraform_data.node_group.output.max_size})"
}
