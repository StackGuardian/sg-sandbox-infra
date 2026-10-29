output "public_ip" {
  description = "Public IP address of the k3s node."
  value       = aws_instance.this.public_ip
}

output "instance_id" {
  description = "ID of the k3s node."
  value       = aws_instance.this.id
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster, with the server set to the public IP."
  value       = local.kubeconfig
  sensitive   = true
}

output "kubeconfig_b64" {
  description = "The kubeconfig, base64-encoded. Pass it to the kubernetes workflow step as KUBECONFIG_DATA."
  value       = local.kubeconfig == "" ? "" : base64encode(local.kubeconfig)
  sensitive   = true
}

output "kubeconfig_status" {
  description = "ok when the kubeconfig was read, otherwise why it is empty."
  value       = data.external.kubeconfig.result.status
}

output "ssh_private_key" {
  description = "Private key for SSH as the ubuntu user, for debugging."
  value       = tls_private_key.this.private_key_openssh
  sensitive   = true
}
