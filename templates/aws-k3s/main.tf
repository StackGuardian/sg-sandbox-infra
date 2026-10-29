resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  name = "${var.name}-${random_id.suffix.hex}"
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Latest Ubuntu 22.04 AMI, from the public SSM parameter Canonical maintains.
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# Network: one public subnet, no NAT gateway.

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = local.name
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# SSH key pair, generated here. The private key stays in the workflow's state.

resource "tls_private_key" "this" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "this" {
  key_name   = local.name
  public_key = tls_private_key.this.public_key_openssh

  tags = {
    Name = local.name
  }
}

# Security group: SSH and the Kubernetes API from allowed_cidr.

resource "aws_security_group" "this" {
  name        = local.name
  description = "k3s node: SSH and Kubernetes API from allowed_cidr."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = local.name
  }
}

resource "aws_vpc_security_group_ingress_rule" "kube_api" {
  security_group_id = aws_security_group.this.id
  description       = "Kubernetes API"
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
  cidr_ipv4         = var.allowed_cidr

  tags = {
    Name = "${local.name}-kube-api"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.this.id
  description       = "SSH"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.allowed_cidr

  tags = {
    Name = "${local.name}-ssh"
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${local.name}-egress"
  }
}

# The k3s node. user_data.sh installs docker and k3s with --tls-san set to the
# public IP, so the API certificate is valid for it.

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.ubuntu.insecure_value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = true

  user_data_base64 = base64encode(file("${path.module}/user_data.sh"))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${local.name}-root"
    }
  }

  tags = {
    Name = local.name
  }

  # A new AMI is published regularly; don't replace the node for it.
  lifecycle {
    ignore_changes = [ami]
  }

  # Wait until k3s has written its kubeconfig. OpenTofu's built-in SSH client
  # does this, so no ssh binary is needed for this step.
  provisioner "remote-exec" {
    when = create

    connection {
      host        = self.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.this.private_key_openssh
      timeout     = "10m"
    }

    inline = [<<-EOT
      until [ -f /etc/rancher/k3s/k3s.yaml ]; do
        echo "The '/etc/rancher/k3s/k3s.yaml' is not available.. Retrying in 10 seconds.."
        sleep 10
      done
      echo "The 'k3s.yaml' has been created. K3s is ready."
      EOT
    ]
  }

  depends_on = [aws_route_table_association.public]
}

# Read the kubeconfig over SSH. It runs at apply time after the node is ready,
# then on every plan, so no file has to survive between runs. Needs `ssh` on
# the runner. When the node can't be reached the outputs are empty instead of
# failing, so a destroy always works.
data "external" "kubeconfig" {
  program = ["sh", "${path.module}/fetch-kubeconfig.sh"]

  query = {
    host    = aws_instance.this.public_ip
    key_b64 = base64encode(tls_private_key.this.private_key_openssh)
  }
}

locals {
  kubeconfig = (
    data.external.kubeconfig.result.kubeconfig_b64 == ""
    ? ""
    : replace(base64decode(data.external.kubeconfig.result.kubeconfig_b64), "127.0.0.1", aws_instance.this.public_ip)
  )
}
