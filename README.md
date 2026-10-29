# StackGuardian sandbox infrastructure

This repository holds the infrastructure code behind your StackGuardian sandbox organization. It is mock code: every resource is a `terraform_data` or `null_resource`, plus one local file. Nothing is created in any cloud, and no cloud credentials or connectors are needed to plan or apply it.

The code is shaped like a real platform team's repository (regional networks around a shared network, a service, a stack that reads a secret, a small template catalog and two policies) so that the workflows, runs, templates and policies in your sandbox look and behave like real ones.

StackGuardian helps enterprises deliver and operate cloud infrastructure through orchestration, policy-driven automation, standardization and self-service. [Tirith](https://github.com/StackGuardian/tirith) is our open-source policy engine.

## What's in your sandbox, and where it comes from

Your workflows sit in nested workflow groups under `project-sandbox`: a `dev` group, and a `prod` group with `shared`, `eu-central-1` and `us-east-2` inside it.

| Workflow | Group | Comes from | What to look at |
|---|---|---|---|
| `dev-network` | `dev` | [`stacks/network`](stacks/network) | Environment variables, a pre-init hook ([`scripts/pre-plan-check.sh`](scripts/pre-plan-check.sh)) and a nightly plan schedule, which is disabled |
| `dev-app` | `dev` | [`stacks/service`](stacks/service) | A run stopped by a change freeze, then a destroy run |
| `dev-vm` | `dev` | Template `vm`, revision 1 | A workflow created from a template. Revision 2 of the template is available, so you can see the upgrade path |
| `core-network` | `prod/shared` | [`stacks/shared-network`](stacks/shared-network) | The shared VPC and the CIDR block reserved for each region, as outputs that the regional networks read. A drift check that found a difference, and a weekly drift check schedule, which is disabled |
| `secrets-demo` | `prod/shared` | [`stacks/secrets-demo`](stacks/secrets-demo) | A token read from a vault secret. Only a short fingerprint of it appears in the outputs. A post-apply hook ([`scripts/post-apply-notify.sh`](scripts/post-apply-notify.sh)) |
| `eu-network` | `prod/eu-central-1` | [`stacks/network`](stacks/network) | Inputs that reference the outputs of `core-network` |
| `eu-app` | `prod/eu-central-1` | [`stacks/service`](stacks/service) | A database engine upgrade waiting for approval. You can approve or reject it |
| `us-network` | `prod/us-east-2` | [`stacks/network`](stacks/network) | The same shared outputs, on OpenTofu 1.8.8 while every other workflow runs 1.11.14. When it completes, it starts `us-app` |
| `us-app` | `prod/us-east-2` | [`stacks/service`](stacks/service) | A run stopped by a policy |

Also in your organization:
- **Templates** `eks-cluster`, `aks-cluster`, `vm` and `ansible-baseline` in the Library, from [`templates/`](templates). `vm` and `eks-cluster` have two revisions each.
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

1. **Re-run a workflow.** Open `dev-network`, start a plan, and compare it with the earlier runs. The pre-init hook prints its context at the top of the log.
2. **Approve a change.** Open `eu-app`. Its latest run waits for approval of a database upgrade from 15 to 16. Approve it or reject it.
3. **Follow an output.** Open the outputs of `core-network`, then the inputs of `eu-network` and `us-network`, which reference them.
4. **Upgrade a template revision.** Open `dev-vm`, which uses revision 1 of `vm`, and move it to revision 2, which adds a data disk.
5. **Deploy a template.** In the Library, open `eks-cluster` (or any other template), create a workflow from it, and fill in the form. The apply creates mock resources only. Turn on **Public API endpoint**, put the workflow in a group under `prod`, and `deny-public-ingress` stops the run.
6. **Read the policies.** Open a policy to see its rule, its scope and its action. Each rule is a short JSON document in [`policies/`](policies).

## Templates

| Template | Kind | Revisions | What it models |
|---|---|---|---|
| `eks-cluster` | OpenTofu | 1: [`templates/eks-cluster`](templates/eks-cluster); 2: [`templates/eks-cluster-v2`](templates/eks-cluster-v2), adds `node_count_max` for node autoscaling | An EKS cluster with its IAM role and a managed node group |
| `aks-cluster` | OpenTofu | 1: [`templates/aks-cluster`](templates/aks-cluster) | An AKS cluster with its resource group and log analytics workspace |
| `vm` | OpenTofu | 1: [`templates/vm`](templates/vm); 2: [`templates/vm-v2`](templates/vm-v2), adds `data_disk_size_gb` for a data disk | A VM with a security group and encrypted volumes |
| `ansible-baseline` | Ansible | 1: [`templates/ansible-baseline`](templates/ansible-baseline) | A server baseline playbook that runs on the workflow runner itself |

Each revision has its own directory, so an older revision never changes when a new one is added. Each template has its input form in `schemas/input_schema.json` and `schemas/ui_schema.json`.

## Policies

| Policy | Rule | Action | Scope |
|---|---|---|---|
| `approve-destructive-changes` | No planned `delete` action on a `terraform_data` resource, which includes replacements | Approval required | Groups `prod/shared`, `prod/eu-central-1` and `prod/us-east-2` |
| `deny-public-ingress` | `input.public_ingress` must be `false` on every `terraform_data` resource | Fail | Every group under `prod` |

See [`policies/README.md`](policies/README.md) for how the rules read the plan, and how to run them locally with Tirith.

## Connect your own cloud and Git

Your sandbox has no cloud connector and no Git connector, on purpose: you are an admin of the organization, so you can add your own.

- **Cloud:** add an [AWS](https://docs.stackguardian.io/docs/connectors/csp/aws/), [Azure](https://docs.stackguardian.io/docs/connectors/csp/azure/) or [GCP](https://docs.stackguardian.io/docs/connectors/csp/gcp/) connector, then deploy real infrastructure from your own code. The mock code in this repository never uses one.
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
