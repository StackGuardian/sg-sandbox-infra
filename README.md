# StackGuardian sandbox infrastructure

This repository holds the infrastructure code behind your StackGuardian sandbox organization. The workflows run mock code: every resource is a `terraform_data` or `null_resource`, plus one local file, so they need no cloud credentials or connectors. The cloud templates in the Library are real: attach your own cloud connector and they create small, low-cost resources in your account.

The code is shaped like a real platform team's repository (regional networks around a shared network, a service, a stack that reads a secret, a small template catalog and two policies) so that the workflows, runs, templates and policies in your sandbox look and behave like real ones.

StackGuardian helps enterprises deliver and operate cloud infrastructure through orchestration, policy-driven automation, standardization and self-service. [Tirith](https://github.com/StackGuardian/tirith) is our open-source policy engine.

## What's in your sandbox, and where it comes from

Your workflows sit in nested workflow groups under `project-sandbox`: a `dev` group, and a `prod` group with `shared`, `eu-central-1` and `us-east-2` inside it.

| Workflow | Group | Comes from | What to look at |
|---|---|---|---|
| `dev-network` | `dev` | [`stacks/network`](stacks/network) | Environment variables, a pre-init hook that writes a line to the run log, and a nightly plan schedule, which is disabled |
| `dev-app` | `dev` | [`stacks/service`](stacks/service) | A run stopped by a change freeze, then a destroy run |
| `dev-vm` | `dev` | Template `vm`, revision 1 | A workflow created from a template. Revision 2 of the template is available, so you can see the upgrade path |
| `core-network` | `prod/shared` | [`stacks/shared-network`](stacks/shared-network) | The shared VPC and the CIDR block reserved for each region, as outputs that the regional networks read. A drift check that found a difference, and a weekly drift check schedule, which is disabled |
| `secrets-demo` | `prod/shared` | [`stacks/secrets-demo`](stacks/secrets-demo) | A token read from a vault secret. Only a short fingerprint of it appears in the outputs. A post-apply hook that writes a line to the run log |
| `eu-network` | `prod/eu-central-1` | [`stacks/network`](stacks/network) | Inputs that reference the outputs of `core-network` |
| `eu-app` | `prod/eu-central-1` | [`stacks/service`](stacks/service) | A database engine upgrade waiting for approval. You can approve or reject it |
| `us-network` | `prod/us-east-2` | [`stacks/network`](stacks/network) | The same shared outputs, on OpenTofu 1.8.8 while every other workflow runs 1.11.14. When it completes, it starts `us-app` |
| `us-app` | `prod/us-east-2` | [`stacks/service`](stacks/service) | A run stopped by a policy |

Also in your organization:
- **Templates** in the Library, from [`templates/`](templates): real cloud templates for AWS, Azure and Google Cloud, plus the mock `vm` template with two revisions. See [Templates](#templates).
- **Policies** `approve-destructive-changes` and `deny-public-ingress`, from [`policies/`](policies).
- **Custom roles** `dev-engineer` and `prod-operator` under Access Management, scoped to the `dev` and `prod` groups. They are not assigned to anyone.
- **Context tags** `env`, `region`, `team` and `cost-center` on every workflow.
- **Pull requests** on this repository: merged changes, and open ones you can browse.

All workflows clone this public repository directly, with no Git connector.

## How each run result is produced

The stacks take a few variables that switch scenarios on. The defaults always give a clean run. One approval is left waiting, so you can approve or reject it yourself.

| Result you see | What causes it |
|---|---|
| Passed | Default variables |
| Failed at plan | `change_freeze = true`: a precondition stops the plan ("Change freeze is active") |
| Failed at apply | `healthy_targets` below the minimum: the rollout check script exits 1 |
| Approval required | A change that replaces a resource, such as a new `db_engine_version`. The `approve-destructive-changes` policy holds the run until an approver signs off, and one rejection cancels it |
| Failed by policy | `public_ingress = true` on a service in a `prod` group. The `deny-public-ingress` policy fails the run |
| Drift detected | The shared network stack writes a runbook file into the run's working directory. A drift check starts on a fresh runner without that file, so it reports a difference |
| Destroyed | A destroy run on `dev-app` |

Each switch is passed to a run as a `TF_VAR_*` environment variable, so the repository itself never changes to produce them.

## Try it yourself

1. **Re-run a workflow.** Open `dev-network`, start a plan, and compare it with the earlier runs. The pre-init hook's line appears near the top of the log.
2. **Approve a change.** Open `eu-app`. Its latest run waits for approval of a database upgrade from 15 to 16. Approve it or reject it.
3. **Follow an output.** Open the outputs of `core-network`, then the inputs of `eu-network` and `us-network`, which reference them.
4. **Upgrade a template revision.** Open `dev-vm`, which uses revision 1 of `vm`, and move it to revision 2, which adds a data disk.
5. **Deploy a template.** Add a cloud connector, then open `aws-s3-bucket` (or another cloud template) in the Library, create a workflow from it with your connector, and keep the form defaults. The apply creates real resources in your account, so run a destroy when you are done.
6. **Read the policies.** Open a policy to see its rule, its scope and its action. Each rule is a short JSON document in [`policies/`](policies).

**Tip:** In this sandbox, a run fails when the plan or apply writes anything to its error output, warnings included. That happens, for example, when you pass a variable the stack doesn't declare, as a `TF_VAR_<name>` environment variable or as an input, or when a hook command fails. Stick to the variables each stack declares in its `variables.tf`.

## Templates

The cloud templates create real resources and need a cloud connector for their cloud. Every input has a working default, except the Google Cloud project ID. Sizes are kept small: a bucket or storage account costs close to nothing, and the VMs are the smallest general-purpose sizes. Destroy them when you are done.

| Template | Cloud | What it creates |
|---|---|---|
| [`aws-s3-bucket`](templates/aws-s3-bucket) | AWS | A private, encrypted, versioned S3 bucket with a lifecycle rule |
| [`aws-ec2-vm`](templates/aws-ec2-vm) | AWS | A t3.micro Amazon Linux 2023 instance in its own VPC, with no inbound access and Session Manager enabled |
| [`aws-k3s`](templates/aws-k3s) | AWS | A single-node [k3s](https://k3s.io) Kubernetes cluster on a t3.small instance. Its kubeconfig is a sensitive output |
| [`azure-storage-account`](templates/azure-storage-account) | Azure | A resource group, a StorageV2 account with blob versioning, and a private container |
| [`azure-linux-vm`](templates/azure-linux-vm) | Azure | A Standard_B1s Ubuntu VM in its own resource group and virtual network, with no inbound access by default |
| [`gcp-gcs-bucket`](templates/gcp-gcs-bucket) | Google Cloud | A private, versioned Cloud Storage bucket |
| [`gcp-e2-micro-vm`](templates/gcp-e2-micro-vm) | Google Cloud | An e2-micro Debian VM in its own VPC, with no inbound access by default |
| `vm` | none (mock) | Revision 1: [`templates/vm`](templates/vm); revision 2: [`templates/vm-v2`](templates/vm-v2), adds `data_disk_size_gb`. Used by `dev-vm` to show the upgrade path |

[`templates/k3s-helm-release`](templates/k3s-helm-release) is a small Helm chart for the podinfo demo app. Deploy it to the `aws-k3s` cluster with a workflow that uses the Kubernetes step, and pass the cluster's `kubeconfig_b64` output as `KUBECONFIG_DATA` with an output reference. See its README.

AWS allows 5 VPCs per region by default. If `aws-ec2-vm` or `aws-k3s` fails with "maximum number of VPCs", turn on **Use the default VPC** or choose another region.

The `eks-cluster` and `aks-cluster` directories hold earlier mock templates that are no longer in the Library.

Each revision has its own directory, so an older revision never changes when a new one is added. Each template has its input form in `schemas/input_schema.json` and `schemas/ui_schema.json`.

## Policies

| Policy | Rule | Action | Scope |
|---|---|---|---|
| `approve-destructive-changes` | No planned `delete` action on a `terraform_data` resource, which includes replacements | Approval required | Groups `prod/shared`, `prod/eu-central-1` and `prod/us-east-2` |
| `deny-public-ingress` | `input.public_ingress` must be `false` on every `terraform_data` resource | Fail | Every group under `prod` |

See [`policies/README.md`](policies/README.md) for how the rules read the plan, and how to run them locally with Tirith.

## Connect your own cloud and Git

Your sandbox has no cloud connector and no Git connector, on purpose: you are an admin of the organization, so you can add your own.

- **Cloud:** add an [AWS](https://docs.stackguardian.io/docs/connectors/csp/aws/), [Azure](https://docs.stackguardian.io/docs/connectors/csp/azure/) or [GCP](https://docs.stackguardian.io/docs/connectors/csp/gcp/) connector, then deploy the cloud templates, or real infrastructure from your own code. The mock workflows never use one.
- **GitHub:** features that depend on a GitHub connector, such as runs triggered by pushes and pull requests, need the [StackGuardian GitHub App](https://docs.stackguardian.io/docs/connectors/vcs/githubcom/) installed for your own GitHub organization and connected to your sandbox. The sandbox does not demonstrate these features, and its pull requests do not trigger runs.

## Run it locally

You need [OpenTofu](https://opentofu.org/) 1.8 or later. The code avoids OpenTofu-only features, so Terraform works too.

```sh
cd templates/vm
tofu init
tofu apply
tofu plan -var 'allowed_cidrs=["0.0.0.0/0"]'
```

`stacks/secrets-demo` needs a token: run it with `TF_VAR_api_token` set to any string of 8 or more characters.

There is no backend block: on StackGuardian, state is managed by the platform; locally, it is a file in the directory.

## Learn more

- [Workflows](https://docs.stackguardian.io/docs/deploy/workflows/overview/)
- [Workflow groups](https://docs.stackguardian.io/docs/deploy/workflow_groups/)
- [Reference variables: workflow outputs and secrets](https://docs.stackguardian.io/docs/deploy/workflows/workflow_components/reference_variables/)
- [Lifecycle hooks and workflow chaining](https://docs.stackguardian.io/docs/deploy/workflows/workflow_components/terraform_config/)
- [Template revisions](https://docs.stackguardian.io/docs/develop/library/manage_template_revisions/)
- [Library and templates](https://docs.stackguardian.io/docs/develop/library/overview/)
- [Policies](https://docs.stackguardian.io/docs/develop/policies/overview/)
- [Tirith](https://github.com/StackGuardian/tirith)

## License

[Apache License 2.0](LICENSE)
