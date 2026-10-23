# Mock of an EKS cluster: IAM role, control plane and one managed node group.
# Each terraform_data carries the attributes a real resource would have, so the
# plan reads like a real one and policies can inspect input.*.

resource "terraform_data" "cluster_role" {
  input = {
    kind           = "aws_iam_role"
    name           = "${var.cluster_name}-cluster"
    assumed_by     = "eks.amazonaws.com"
    public_ingress = false
    tags           = var.tags
  }
}

resource "terraform_data" "cluster" {
  input = {
    kind               = "aws_eks_cluster"
    name               = var.cluster_name
    region             = var.region
    kubernetes_version = var.kubernetes_version
    role               = terraform_data.cluster_role.output.name
    public_ingress     = var.endpoint_public_access
    encrypted          = true
    tags               = var.tags
  }
}

resource "terraform_data" "node_group" {
  input = {
    kind           = "aws_eks_node_group"
    name           = "${var.cluster_name}-default"
    cluster        = terraform_data.cluster.output.name
    instance_type  = var.node_instance_type
    desired_size   = var.node_count
    public_ingress = false
    tags           = var.tags
  }
}
