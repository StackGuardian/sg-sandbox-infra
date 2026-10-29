#!/bin/bash
# Installs docker and k3s, then writes the kubeconfig (server set to the public
# IP) to the SSM parameter ${kubeconfig_ssm}. Rendered with templatefile().

set -e

# Update system
apt update
apt install -y docker.io

# Start Docker
systemctl start --now docker

# Install K3s
PUBLIC_IP="$(curl -s http://checkip.amazonaws.com)"
BIND_ADDRESS="0.0.0.0"
INSTALL_K3S_EXEC="server --tls-san $PUBLIC_IP --node-external-ip $PUBLIC_IP --bind-address $BIND_ADDRESS"
curl -sfL https://get.k3s.io |
  INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -

# Ensure K3s service is running
systemctl enable --now k3s

until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 5; done

# Publish the kubeconfig. k3s writes 127.0.0.1 or 0.0.0.0 as the server.
snap install aws-cli --classic
sed -E "s#https://(127\.0\.0\.1|0\.0\.0\.0):6443#https://$PUBLIC_IP:6443#" /etc/rancher/k3s/k3s.yaml >/root/kubeconfig
/snap/bin/aws ssm put-parameter --region "${region}" --name "${kubeconfig_ssm}" \
  --type SecureString --overwrite --value "file:///root/kubeconfig"
rm -f /root/kubeconfig
