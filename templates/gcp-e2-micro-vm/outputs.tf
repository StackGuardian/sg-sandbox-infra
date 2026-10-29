output "instance_name" {
  description = "Name of the VM."
  value       = google_compute_instance.this.name
}

output "zone" {
  description = "Zone of the VM."
  value       = google_compute_instance.this.zone
}

output "internal_ip" {
  description = "Internal IP address of the VM."
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "Ephemeral external IP of the VM, or null when external_ip_enabled is false."
  value       = try(google_compute_instance.this.network_interface[0].access_config[0].nat_ip, null)
}

output "network_name" {
  description = "Name of the VPC network."
  value       = google_compute_network.this.name
}
