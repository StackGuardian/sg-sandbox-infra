# azure-linux-vm

Creates a small Ubuntu 24.04 LTS VM (`Standard_B1s` by default) in its own resource group and VNet (`10.70.0.0/16`). The network security group has no inbound rules unless you set `allowed_ssh_cidrs`. Login is by a generated SSH key only; password login is off.

The VM stops (deallocates) every day at 19:00 UTC by default, so a forgotten VM costs only its disk. Change the time with `auto_shutdown_time`, or turn it off with `auto_shutdown_enabled`.

Attach an Azure cloud connector. Every input has a default; leave `subscription_id` empty to use the connector's subscription.

| Output | Description |
|---|---|
| `resource_group_name` | Name of the resource group |
| `vm_id` | Resource ID of the VM |
| `public_ip` | Public IP, or null when `public_ip_enabled` is false |
| `admin_username` | Admin user for SSH (`azureuser`) |
| `ssh_private_key` | Generated private key (sensitive) |
