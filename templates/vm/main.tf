# Mock of a single VM: security group, encrypted root volume and instance.
# Each terraform_data carries the attributes a real resource would have, so
# policies can inspect input.*.

locals {
  public_ingress = contains(var.allowed_cidrs, "0.0.0.0/0")
}

resource "terraform_data" "security_group" {
  input = {
    kind           = "aws_security_group"
    name           = "${var.name}-sg"
    region         = var.region
    ingress_port   = 443
    ingress_cidrs  = var.allowed_cidrs
    public_ingress = local.public_ingress
    tags           = var.tags
  }
}

resource "terraform_data" "root_volume" {
  input = {
    kind           = "aws_ebs_volume"
    name           = "${var.name}-root"
    size_gb        = var.disk_size_gb
    encrypted      = true
    public_ingress = false
    tags           = var.tags
  }
}

resource "terraform_data" "instance" {
  input = {
    kind           = "aws_instance"
    name           = var.name
    region         = var.region
    instance_type  = var.instance_type
    security_group = terraform_data.security_group.output.name
    root_volume    = terraform_data.root_volume.output.name
    public_ingress = local.public_ingress
    tags           = var.tags
  }
}
