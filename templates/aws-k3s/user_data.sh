#!/bin/bash

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
