# aws-k3s

Creates a VPC with one public subnet, then a single Ubuntu 22.04 EC2 node running docker and [k3s](https://k3s.io). The API certificate includes the node's public IP, so you can reach the cluster from outside.

The template generates an ED25519 key pair, waits over SSH until k3s has written its kubeconfig, then reads it and returns it as outputs with the server set to the public IP.

Needs an AWS cloud connector, and `ssh` on the runner that applies it. Every input has a working default.

**Restrict `allowed_cidr`.** It opens SSH (22) and the Kubernetes API (6443) and defaults to `0.0.0.0/0`. The runner must stay inside the range, because it reads the kubeconfig over SSH.

| Output | Description |
|---|---|
| `public_ip` | Public IP address of the node |
| `instance_id` | ID of the node |
| `kubeconfig` | Kubeconfig (sensitive) |
| `kubeconfig_b64` | Kubeconfig, base64-encoded, for the kubernetes workflow step's `KUBECONFIG_DATA` (sensitive) |
| `kubeconfig_status` | `ok`, or why the kubeconfig is empty |
| `ssh_private_key` | SSH private key for the `ubuntu` user (sensitive) |
