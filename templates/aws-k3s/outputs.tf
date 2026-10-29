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
  value       = local.kubeconfig_ready ? "ok" : "not published yet: k3s is still starting; run the workflow again in a few minutes"
}

output "ssm_connect_command" {
  description = "Command to open a shell on the node with Session Manager."
  value       = "aws ssm start-session --region ${var.region} --target ${aws_instance.this.id}"
}
