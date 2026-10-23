output "cluster_name" {
  description = "Name of the mock AKS cluster."
  value       = terraform_data.cluster.output.name
}

output "cluster_fqdn" {
  description = "Mock API server FQDN. The .invalid domain never resolves."
  value       = "${terraform_data.cluster.output.name}.${var.location}.azmk8s.example.invalid"
}

output "node_pool" {
  description = "Default node pool VM size and count."
  value       = "${terraform_data.cluster.output.node_vm_size} x ${terraform_data.cluster.output.node_count}"
}
