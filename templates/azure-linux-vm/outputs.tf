output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "vm_id" {
  description = "Resource ID of the VM."
  value       = azurerm_linux_virtual_machine.this.id
}

output "public_ip" {
  description = "Public IP address of the VM, or null when public_ip_enabled is false."
  value       = var.public_ip_enabled ? azurerm_public_ip.this[0].ip_address : null
}

output "admin_username" {
  description = "Admin user name for SSH."
  value       = local.admin_username
}

output "ssh_private_key" {
  description = "Generated SSH private key for the admin user, in PEM format."
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}
