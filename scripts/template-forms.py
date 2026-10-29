#!/usr/bin/env python3
"""Writes templates/<name>/schemas/{input,ui}_schema.json, the StackGuardian
no-code forms, for the real cloud templates. Edit the field lists here and
rerun; the forms must stay in step with each template's variables.tf.

Usage: scripts/template-forms.py [templates-dir]
"""
import json, os, sys
root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "templates")
CIDR = r"^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$"
CIDR24 = r"^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|1[0-9]|2[0-4])$"
VPC_QUOTA = "AWS allows 5 VPCs per region by default. If the deploy fails with \"maximum number of VPCs\", turn this on or choose another region. The region must still have its default VPC."

def pick(title, typ, opts, default, **extra):
    d = {"title": title, "type": typ, "enum": [o[0] for o in opts], "enumNames": [o[1] for o in opts], "default": default}
    d.update(extra)
    return d

AWS_REGION_OPTS = [
  ("us-east-1", "US East (N. Virginia)"), ("us-east-2", "US East (Ohio)"), ("us-west-2", "US West (Oregon)"),
  ("eu-central-1", "Europe (Frankfurt)"), ("eu-west-1", "Europe (Ireland)"), ("eu-west-2", "Europe (London)"),
  ("ap-south-1", "Asia Pacific (Mumbai)"), ("ap-southeast-1", "Asia Pacific (Singapore)"), ("ap-northeast-1", "Asia Pacific (Tokyo)"),
]
AZURE_LOCATION_OPTS = [
  ("eastus", "US: East US"), ("westus2", "US: West US 2"),
  ("westeurope", "Europe: West Europe (Netherlands)"), ("northeurope", "Europe: North Europe (Ireland)"), ("germanywestcentral", "Europe: Germany West Central"),
  ("southeastasia", "Asia: Southeast Asia (Singapore)"), ("japaneast", "Asia: Japan East"),
]
GCP_REGION_OPTS = [
  ("us-central1", "US: Iowa (us-central1), e2-micro free tier"), ("us-east1", "US: South Carolina (us-east1), e2-micro free tier"), ("us-west1", "US: Oregon (us-west1), e2-micro free tier"),
  ("europe-west1", "Europe: Belgium (europe-west1)"), ("europe-west3", "Europe: Frankfurt (europe-west3)"),
  ("asia-southeast1", "Asia: Singapore (asia-southeast1)"), ("asia-northeast1", "Asia: Tokyo (asia-northeast1)"),
]
SEL = {"ui:widget": "select"}

def aws_region(default="eu-central-1"):
    return pick("AWS Region", "string", AWS_REGION_OPTS, default)

T = {}
T["aws-s3-bucket"] = [
  ("region", aws_region(), {"ui:widget": "select", "ui:description": "AWS region for the bucket."}),
  ("bucket_prefix", {"title": "Bucket name prefix", "type": "string", "pattern": "^[a-z0-9][a-z0-9-]{1,45}$", "default": "sg-sandbox"},
     {"ui:placeholder": "sg-sandbox", "ui:description": "Start of the bucket name. A random suffix is added so the name is globally unique."}),
  ("versioning_enabled", {"title": "Versioning", "type": "boolean", "default": True}, {"ui:widget": "checkbox", "ui:description": "Keep previous versions of objects."}),
  ("noncurrent_version_expiration_days", pick("Delete old versions after", "number", [(7, "7 days"), (30, "30 days"), (90, "90 days"), (365, "365 days")], 30),
     dict(SEL, **{"ui:description": "Days after which previous object versions are deleted."})),
]
def aws_net(default_name, cidr, sizes, size_def, itypes, itype, itype_desc):
    return [
      ("region", aws_region(), {"ui:widget": "select", "ui:description": "AWS region for every resource."}),
      ("name", {"title": "Name prefix", "type": "string", "pattern": "^(?!sg-)[a-z][a-z0-9-]{1,30}$", "default": default_name},
         {"ui:placeholder": default_name, "ui:description": "Name prefix for every resource. A random suffix is added. Lowercase letters, digits and hyphens; must not start with \"sg-\"."}),
      ("use_default_vpc", {"title": "Use the default VPC", "type": "boolean", "default": False},
         {"ui:widget": "checkbox", "ui:description": "Deploy into the region's default VPC instead of creating a new one. " + VPC_QUOTA}),
      ("vpc_cidr", {"title": "VPC CIDR", "type": "string", "pattern": CIDR24, "default": cidr},
         {"ui:placeholder": cidr, "ui:description": "CIDR range of the new VPC (/24 or larger). The public subnet uses its first /24. Ignored when the default VPC is used."}),
      ("instance_type", pick("Instance type", "string", itypes, itype), dict(SEL, **{"ui:description": itype_desc})),
      ("root_volume_size_gb", pick("Root volume size", "number", [(n, f"{n} GiB") for n in sizes], size_def),
         dict(SEL, **{"ui:description": "Size of the encrypted gp3 root volume."})),
    ]
T["aws-ec2-vm"] = aws_net("sandbox-vm", "10.60.0.0/16", [8, 16, 32], 8,
  [("t3.nano", "t3.nano: 2 vCPU, 0.5 GiB"), ("t3.micro", "t3.micro: 2 vCPU, 1 GiB"), ("t3.small", "t3.small: 2 vCPU, 2 GiB"),
   ("t4g.nano", "t4g.nano: 2 vCPU, 0.5 GiB, Graviton (arm64)"), ("t4g.micro", "t4g.micro: 2 vCPU, 1 GiB, Graviton (arm64)"), ("t4g.small", "t4g.small: 2 vCPU, 2 GiB, Graviton (arm64)")],
  "t3.micro", "EC2 instance type. All are burstable and low-cost; Graviton (t4g) sizes cost about 20% less, and the AMI is picked to match.") + [
  ("allowed_ingress_cidrs", {"title": "SSH allowed from", "type": "array", "items": {"type": "string", "pattern": CIDR}, "default": []},
     {"items": {"ui:placeholder": "203.0.113.0/24"}, "ui:description": "CIDR ranges allowed to reach the instance on SSH (port 22). Leave empty for no inbound access and connect with Session Manager instead."}),
]
T["aws-k3s"] = aws_net("sandbox-k3s", "10.61.0.0/16", [20, 40], 20,
  [("t3.small", "t3.small: 2 vCPU, 2 GiB"), ("t3.medium", "t3.medium: 2 vCPU, 4 GiB")],
  "t3.small", "EC2 instance type. k3s needs about 2 GiB of memory; pick t3.medium for more workloads.") + [
  ("allowed_cidr", {"title": "Kubernetes API allowed from", "type": "string", "pattern": CIDR, "default": "0.0.0.0/0"},
     {"ui:placeholder": "203.0.113.0/24", "ui:description": "**Restrict this.** CIDR range allowed to reach the Kubernetes API (6443). The default is open to the internet. Runs that use the kubeconfig, such as a Helm release, must come from inside it. SSH is closed; use Session Manager for a shell."}),
  ("kubeconfig_wait_seconds", pick("Wait for the kubeconfig", "number", [(180, "3 minutes"), (300, "5 minutes"), (600, "10 minutes")], 300),
     dict(SEL, **{"ui:description": "How long the first apply waits for k3s to publish its kubeconfig. If the kubeconfig output is still empty, run the workflow again."})),
]
T["azure-storage-account"] = [
  ("location", pick("Azure region", "string", AZURE_LOCATION_OPTS, "westeurope"), dict(SEL, **{"ui:description": "Azure region for the resource group and the storage account."})),
  ("name_prefix", {"title": "Name prefix", "type": "string", "pattern": "^[a-z][a-z0-9]{2,15}$", "default": "sgsandbox"},
     {"ui:placeholder": "sgsandbox", "ui:description": "3-16 lowercase letters or digits. A random suffix is added to keep names unique."}),
  ("container_name", {"title": "Container name", "type": "string", "pattern": "^[a-z0-9](-?[a-z0-9])+$", "maxLength": 63, "default": "data"},
     {"ui:placeholder": "data", "ui:description": "Name of the private blob container."}),
]
T["azure-linux-vm"] = [
  ("location", pick("Azure region", "string", AZURE_LOCATION_OPTS, "westeurope"), dict(SEL, **{"ui:description": "Azure region for every resource."})),
  ("name_prefix", {"title": "Name prefix", "type": "string", "pattern": "^[a-z][a-z0-9-]{1,18}[a-z0-9]$", "default": "sgsandbox"},
     {"ui:placeholder": "sgsandbox", "ui:description": "3-20 lowercase letters, digits or hyphens. A random suffix is added to keep names unique."}),
  ("vm_size", pick("VM size", "string", [("Standard_B1s", "B1s: 1 vCPU, 1 GiB"), ("Standard_B1ms", "B1ms: 1 vCPU, 2 GiB"), ("Standard_B2s", "B2s: 2 vCPU, 4 GiB")], "Standard_B1s"),
     dict(SEL, **{"ui:description": "Azure VM size. All three are burstable B-series sizes."})),
  ("os_disk_size_gb", pick("OS disk size", "number", [(30, "30 GiB"), (64, "64 GiB"), (128, "128 GiB")], 30), dict(SEL, **{"ui:description": "Size of the OS disk."})),
  ("public_ip_enabled", {"title": "Public IP", "type": "boolean", "default": True}, {"ui:widget": "checkbox", "ui:description": "Give the VM a Standard SKU static public IP."}),
  ("allowed_ssh_cidrs", {"title": "SSH allowed from", "type": "array", "items": {"type": "string", "pattern": CIDR}, "default": []},
     {"items": {"ui:placeholder": "203.0.113.0/24"}, "ui:description": "CIDR ranges allowed to reach the VM on port 22. Leave empty for no inbound traffic at all."}),
  ("auto_shutdown_enabled", {"title": "Daily auto-shutdown", "type": "boolean", "default": True},
     {"ui:widget": "checkbox", "ui:description": "Stop (deallocate) the VM every day at the time below, so a forgotten VM costs only its disk."}),
  ("auto_shutdown_time", pick("Shutdown time (UTC)", "string", [("1700", "17:00"), ("1900", "19:00"), ("2100", "21:00"), ("2300", "23:00")], "1900"),
     dict(SEL, **{"ui:description": "Daily shutdown time, in UTC."})),
]
GCP_PROJECT = ("project_id", {"title": "Project ID", "type": "string", "pattern": "^[a-z][a-z0-9-]{4,28}[a-z0-9]$", "minLength": 6},
   {"ui:placeholder": "my-project-id", "ui:description": "ID of the Google Cloud project to deploy into. Required: a cloud connector doesn't choose a project."})
T["gcp-gcs-bucket"] = [
  GCP_PROJECT,
  ("region", pick("Google Cloud region", "string", GCP_REGION_OPTS, "us-central1"), dict(SEL, **{"ui:description": "Region used as the bucket location."})),
  ("bucket_prefix", {"title": "Bucket name prefix", "type": "string", "pattern": "^[a-z][a-z0-9-]{1,38}[a-z0-9]$", "default": "sgsandbox"},
     {"ui:placeholder": "sgsandbox", "ui:description": "A random suffix is added to keep the name globally unique."}),
  ("noncurrent_version_retention_days", pick("Delete old versions after", "number", [(7, "7 days"), (30, "30 days"), (90, "90 days"), (365, "365 days")], 30),
     dict(SEL, **{"ui:description": "Days to keep a noncurrent object version before it is deleted."})),
]
T["gcp-e2-micro-vm"] = [
  GCP_PROJECT,
  ("region", pick("Google Cloud region", "string", GCP_REGION_OPTS, "us-central1"), dict(SEL, **{"ui:description": "Region for the network and the VM. The e2-micro free tier applies in the three US regions."})),
  ("zone", {"title": "Zone (optional)", "type": "string", "pattern": "^$|^[a-z]+-[a-z]+[0-9]-[a-z]$", "default": ""},
     {"ui:placeholder": "us-central1-b", "ui:description": "Zone for the VM, in the region above. Leave empty to use the region's first available zone."}),
  ("name_prefix", {"title": "Name prefix", "type": "string", "pattern": "^[a-z][a-z0-9-]{1,38}[a-z0-9]$", "default": "sgsandbox"},
     {"ui:placeholder": "sgsandbox", "ui:description": "A random suffix is added to keep names unique."}),
  ("machine_type", pick("Machine type", "string", [("e2-micro", "e2-micro: 2 shared vCPU, 1 GB"), ("e2-small", "e2-small: 2 shared vCPU, 2 GB"), ("e2-medium", "e2-medium: 2 shared vCPU, 4 GB")], "e2-micro"),
     dict(SEL, **{"ui:description": "Machine type. e2-micro is in the Google Cloud free tier in the three US regions."})),
  ("external_ip_enabled", {"title": "External IP", "type": "boolean", "default": True}, {"ui:widget": "checkbox", "ui:description": "Give the VM an ephemeral external IP."}),
  ("allowed_ssh_cidrs", {"title": "SSH allowed from", "type": "array", "items": {"type": "string", "pattern": CIDR}, "default": []},
     {"items": {"ui:placeholder": "203.0.113.0/24"}, "ui:description": "CIDR ranges allowed to reach the VM on port 22. Leave empty for no inbound traffic at all."}),
  ("spot", {"title": "Spot VM", "type": "boolean", "default": False},
     {"ui:widget": "checkbox", "ui:description": "Much cheaper, but Google can stop the VM at any time. A stopped Spot VM keeps its disk."}),
]
for name, fields in T.items():
    inp = {"type": "object", "properties": {k: v for k, v, _ in fields}}
    req = [k for k, v, _ in fields if "default" not in v]
    if req: inp["required"] = req
    ui = {"ui:order": [k for k, _, _ in fields]}
    for k, _, u in fields: ui[k] = u
    d = os.path.join(root, name, "schemas"); os.makedirs(d, exist_ok=True)
    for fn, obj in (("input_schema.json", inp), ("ui_schema.json", ui)):
        with open(os.path.join(d, fn), "w") as f: json.dump(obj, f, indent=2); f.write("\n")
    print(name, len(fields), "fields, required:", req)
