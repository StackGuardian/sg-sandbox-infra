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

# Latest Amazon Linux 2023 AMI, from the public SSM parameter AWS maintains.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
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

# Security group: no inbound by default. Outbound is open so the SSM agent
# can reach Session Manager.

resource "aws_security_group" "this" {
  name        = local.name
  description = "Sandbox VM. No inbound unless allowed_ingress_cidrs is set."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = local.name
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.this.id
  description       = "SSH"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value

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

# IAM: lets Session Manager connect to the instance.

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

resource "aws_iam_instance_profile" "this" {
  name = local.name
  role = aws_iam_role.this.name

  tags = {
    Name = local.name
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true

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

  # A new AMI is published regularly; don't replace the instance for it.
  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [
    aws_route_table_association.public,
    aws_iam_role_policy_attachment.ssm,
  ]
}
