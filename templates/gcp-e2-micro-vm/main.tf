# An e2-micro Debian VM in its own VPC. The VPC has no inbound firewall rule
# unless allowed_ssh_cidrs is set; GCP denies inbound traffic by default.

locals {
  labels = {
    managed-by       = "stackguardian-sandbox"
    sandbox-template = "gcp-e2-micro-vm"
  }
  name = "${var.name_prefix}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "google_compute_network" "this" {
  name                    = "vpc-${local.name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = "snet-${local.name}"
  network       = google_compute_network.this.id
  region        = var.region
  ip_cidr_range = "10.80.0.0/24"
}

resource "google_compute_firewall" "ssh" {
  count = length(var.allowed_ssh_cidrs) > 0 ? 1 : 0

  name          = "allow-ssh-${local.name}"
  network       = google_compute_network.this.id
  direction     = "INGRESS"
  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "this" {
  name         = "vm-${local.name}"
  zone         = var.zone
  machine_type = var.machine_type
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image  = "debian-cloud/debian-12"
      size   = 10
      type   = "pd-standard"
      labels = local.labels
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id

    dynamic "access_config" {
      for_each = var.external_ip_enabled ? [1] : []
      content {}
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}
