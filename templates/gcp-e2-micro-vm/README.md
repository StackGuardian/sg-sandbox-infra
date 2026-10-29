# gcp-e2-micro-vm

Creates an `e2-micro` Debian 12 VM with a 10 GB `pd-standard` boot disk and Shielded VM on, in its own VPC with one subnet (`10.80.0.0/24`). There is no inbound firewall rule unless you set `allowed_ssh_cidrs`. The VM gets an ephemeral external IP unless `external_ip_enabled` is false. OS Login is on.

Attach a GCP cloud connector and set `project_id`. Every other input has a default.

| Output | Description |
|---|---|
| `instance_name` | Name of the VM |
| `zone` | Zone of the VM |
| `internal_ip` | Internal IP |
| `external_ip` | Ephemeral external IP, or null |
| `network_name` | Name of the VPC |
