# ansible-baseline (mock)

A server baseline playbook that runs on the workflow runner itself (`localhost`,
`connection: local`). It needs no inventory, SSH key or cloud connector, and it
only writes files under `/tmp/sg-sandbox/`.

What it does:

1. Prints what a real baseline would configure (packages, time sync, SSH hardening).
2. Writes the package list and SSH hardening settings to files, standing in for
   installing packages and editing `sshd_config`.
3. Checks the files exist.

Variables, all optional: `app_name` (default `demo-app`), `environment_name`
(default `sandbox`), `packages` (default `["nginx", "chrony"]`).

To point it at real servers, replace `hosts: localhost` and `connection: local`
with your own inventory and connection settings.
