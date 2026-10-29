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

# Network: by default its own VPC with one public subnet and no NAT gateway.
# With use_default_vpc the account's default VPC is used instead, which avoids
# the per-region VPC quota (5 by default).

# aws_vpcs (not aws_vpc) so a region without a default VPC gets a clear error.
data "aws_vpcs" "default" {
  count = var.use_default_vpc ? 1 : 0

  filter {
    name   = "is-default"
    values = ["true"]
  }
}

data "aws_subnets" "default" {
  count = var.use_default_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = data.aws_vpcs.default[0].ids
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "availability-zone"
    values = [data.aws_availability_zones.available.names[0]]
  }

  lifecycle {
    precondition {
      condition     = length(data.aws_vpcs.default[0].ids) == 1
      error_message = "use_default_vpc is true, but ${var.region} has no default VPC. Set use_default_vpc to false or choose a region that has one."
    }
  }
}

resource "aws_vpc" "this" {
  count = var.use_default_vpc ? 0 : 1

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.name
  }
}

resource "aws_internet_gateway" "this" {
  count = var.use_default_vpc ? 0 : 1

  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = local.name
  }
}

resource "aws_subnet" "public" {
  count = var.use_default_vpc ? 0 : 1

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table" "public" {
  count = var.use_default_vpc ? 0 : 1

  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table_association" "public" {
  count = var.use_default_vpc ? 0 : 1

  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

locals {
  vpc_id    = var.use_default_vpc ? data.aws_vpcs.default[0].ids[0] : aws_vpc.this[0].id
  subnet_id = var.use_default_vpc ? data.aws_subnets.default[0].ids[0] : aws_subnet.public[0].id
}

# The node writes its kubeconfig to an SSM SecureString parameter, and this
# template reads it from there, so nothing connects to the node over SSH. The
# instance role can write only that parameter, plus Session Manager for a shell.

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = {
    Name = local.name
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "kubeconfig" {
  statement {
    actions   = ["ssm:PutParameter"]
    resources = [aws_ssm_parameter.kubeconfig.arn]
  }
}

resource "aws_iam_role_policy" "kubeconfig" {
  name   = "write-kubeconfig"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.kubeconfig.json
}

resource "aws_iam_instance_profile" "this" {
  role = aws_iam_role.this.name

  tags = {
    Name = local.name
  }
}

# Created with a placeholder; the node overwrites it once k3s is up. Destroyed
# with the rest of the template.
resource "aws_ssm_parameter" "kubeconfig" {
  name  = "/sg-sandbox/${local.name}/kubeconfig"
  type  = "SecureString"
  value = "pending"

  tags = {
    Name = local.name
  }

  lifecycle {
    ignore_changes = [value]
  }
}

# Security group: the Kubernetes API from allowed_cidr. No SSH.

resource "aws_security_group" "this" {
  name        = local.name
  description = "k3s node: Kubernetes API from allowed_cidr."
  vpc_id      = local.vpc_id

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
  iam_instance_profile        = aws_iam_instance_profile.this.name
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = true

  user_data_base64 = base64encode(templatefile("${path.module}/user_data.sh", {
    region         = var.region
    kubeconfig_ssm = aws_ssm_parameter.kubeconfig.name
  }))

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

  depends_on = [aws_route_table_association.public, aws_iam_role_policy.kubeconfig]
}

# k3s takes a few minutes to install and publish its kubeconfig. Wait once,
# after the node is created; later plans read the parameter directly.
resource "time_sleep" "k3s" {
  create_duration = "${var.kubeconfig_wait_seconds}s"

  triggers = {
    instance_id = aws_instance.this.id
  }
}

data "aws_ssm_parameter" "kubeconfig" {
  name            = aws_ssm_parameter.kubeconfig.name
  with_decryption = true

  depends_on = [time_sleep.k3s]
}

locals {
  kubeconfig_ready = nonsensitive(data.aws_ssm_parameter.kubeconfig.value != "pending")
  kubeconfig       = local.kubeconfig_ready ? data.aws_ssm_parameter.kubeconfig.value : ""
}
