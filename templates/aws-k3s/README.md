# aws-k3s

Creates a VPC with one public subnet, then a single Ubuntu 22.04 EC2 node running docker and [k3s](https://k3s.io). The API certificate includes the node's public IP, so you can reach the cluster from outside.

Once k3s is up, the node writes its kubeconfig, with the server set to the public IP, to an SSM SecureString parameter. The template waits for it (`kubeconfig_wait_seconds`, 5 minutes by default) and returns it as outputs. Nothing connects to the node over SSH; port 22 is closed, and the node has Session Manager for a shell.

Needs an AWS cloud connector. Every input has a working default.

**Restrict `allowed_cidr`.** It opens the Kubernetes API (6443) and defaults to `0.0.0.0/0`. Runs that use the kubeconfig, such as a Helm release, must come from inside the range.

If `kubeconfig_status` says the kubeconfig isn't published yet, k3s took longer than the wait: run the workflow again.

**VPC quota.** AWS allows 5 VPCs per region by default. If the deploy fails with "maximum number of VPCs", set `use_default_vpc` to `true` to use the region's default VPC instead, or choose another region.

| Output | Description |
|---|---|
| `public_ip` | Public IP address of the node |
| `instance_id` | ID of the node |
| `kubeconfig` | Kubeconfig (sensitive) |
| `kubeconfig_b64` | Kubeconfig, base64-encoded, for the kubernetes workflow step's `KUBECONFIG_DATA` (sensitive) |
| `kubeconfig_status` | `ok`, or why the kubeconfig is empty |
| `ssm_connect_command` | Session Manager command for a shell on the node |
