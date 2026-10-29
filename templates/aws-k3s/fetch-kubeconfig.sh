#!/bin/sh
# Program for data "external" "kubeconfig". Reads {"host": "...", "key_b64": "..."}
# on stdin and prints {"kubeconfig_b64": "...", "status": "..."}.
# Needs ssh, base64, sed, tr and mktemp. Never fails: when the node can't be
# reached, kubeconfig_b64 is empty and status says why, so a destroy still
# works when the node is stopped or gone.
set -u

input="$(cat)"
host="$(printf '%s' "$input" | sed -n 's/.*"host" *: *"\([^"]*\)".*/\1/p')"
key_b64="$(printf '%s' "$input" | sed -n 's/.*"key_b64" *: *"\([A-Za-z0-9+/=]*\)".*/\1/p')"

result() {
  printf '{"kubeconfig_b64":"%s","status":"%s"}\n' "$1" "$2"
  exit 0
}

[ -n "$host" ] || result "" "node has no public IP"
command -v ssh >/dev/null 2>&1 || result "" "ssh is not installed on the runner"

keyfile="$(mktemp)"
trap 'rm -f "$keyfile"' EXIT
printf '%s' "$key_b64" | base64 -d >"$keyfile" 2>/dev/null
chmod 600 "$keyfile"

kubeconfig_b64="$(
  ssh -i "$keyfile" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout=20 \
    "ubuntu@$host" \
    "sudo base64 -w0 /etc/rancher/k3s/k3s.yaml" 2>/dev/null | tr -d '\n'
)"

[ -n "$kubeconfig_b64" ] || result "" "could not read the kubeconfig over SSH from $host"
result "$kubeconfig_b64" "ok"
