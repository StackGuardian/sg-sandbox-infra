# StackGuardian sandbox infrastructure

This repository holds the infrastructure code behind your StackGuardian sandbox organization. It is mock code: every resource is a `terraform_data` or `null_resource`, plus one local file. Nothing is created in any cloud, and no cloud credentials or connectors are needed to plan or apply it.

The code is shaped like a real platform team's repository (a network, a service and an ops stack, plus a small template catalog and two policies) so that the workflows, runs, templates and policies in your sandbox look and behave like real ones.

StackGuardian helps enterprises deliver and operate cloud infrastructure through orchestration, policy-driven automation, standardization and self-service. [Tirith](https://github.com/StackGuardian/tirith) is our open-source policy engine.

## What's in your sandbox, and where it comes from

| In your organization | Comes from | What to look at |
|---|---|---|
| Workflow `prod-network` in group `platform-prod` | [`stacks/network`](stacks/network) | Plans and applies of a VPC with subnets, NAT and a security baseline, and a network change that needed approval |
| Workflow `prod-checkout-api` in group `platform-prod` | [`stacks/service`](stacks/service) | A service rollout: passing runs, a run stopped by a change freeze, a run whose rollout check failed, and approval for a database engine upgrade |
| Workflow `prod-ops` in group `platform-ops` | [`stacks/ops`](stacks/ops) | Alerting, backups and a status page: a drift check that found a difference, and a run stopped by a policy |
| Templates `eks-cluster`, `aks-cluster`, `vm`, `ansible-baseline` in the Library | [`templates/`](templates) | Reusable templates with input forms. You can create a workflow from any of them |
| Policies `approve-destructive-changes` and `deny-public-ingress` | [`policies/`](policies) | The Tirith rules behind the approval and the policy failure |
| Pull requests on this repository | GitHub | Merged changes, and three open ones you can browse |

All workflows clone this public repository directly, with no Git connector.

## How each run result is produced

The stacks take a few variables that switch scenarios on. The defaults always give a clean run. One approval is left waiting, so you can approve or reject it yourself.

| Result you see | What causes it |
|---|---|
| Passed | Default variables |
| Failed at plan | `change_freeze = true`: a precondition stops the plan ("Change freeze is active") |
| Failed at apply | `healthy_targets` below the minimum: the rollout check script exits 1 |
| Approval required | A change that replaces a resource, such as a new `vpc_cidr` or `db_engine_version`. The `approve-destructive-changes` policy holds the run until an approver signs off, and one rejection cancels it |
| Failed by policy | `public_ingress = true` on the status page. The `deny-public-ingress` policy fails the run |
| Drift detected | The ops stack writes a runbook file. When that file is missing or changed outside OpenTofu, a drift check reports the difference |

Each switch is passed to a run as a `TF_VAR_*` environment variable, so the repository itself never changes to produce them.

## Try it yourself

1. **Re-run a workflow.** Open `prod-network`, start a plan, and compare it with the earlier runs.
2. **Trigger the approval.** In the settings of `prod-network`, add the environment variable `TF_VAR_vpc_cidr` with the value `10.41.0.0/16`, then run it. The plan replaces the network, so the run waits for approval. Approve it or reject it, then remove the variable.
3. **Deploy a template.** In the Library, open `eks-cluster` (or any other template), create a workflow from it, and fill in the form. The apply creates mock resources only. Turn on **Public API endpoint**, put the workflow in the `platform-ops` group, and `deny-public-ingress` stops the run.
4. **Read the policies.** Open a policy to see its rule, its scope and its action. Each rule is a short JSON document in [`policies/`](policies).

## Templates

| Template | Kind | What it models |
|---|---|---|
| [`eks-cluster`](templates/eks-cluster) | OpenTofu | An EKS cluster with its IAM role and a managed node group |
| [`aks-cluster`](templates/aks-cluster) | OpenTofu | An AKS cluster with its resource group and log analytics workspace |
| [`vm`](templates/vm) | OpenTofu | A VM with a security group and an encrypted root volume |
| [`ansible-baseline`](templates/ansible-baseline) | Ansible | A server baseline playbook that runs on the workflow runner itself |

Each template has its input form in `schemas/input_schema.json` and `schemas/ui_schema.json`.

## Policies

| Policy | Rule | Action | Scope |
|---|---|---|---|
| `approve-destructive-changes` | No planned `delete` action, which includes replacements | Approval required | Group `platform-prod` |
| `deny-public-ingress` | `input.public_ingress` must be `false` on every resource that sets it | Fail | Group `platform-ops` |

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

There is no backend block: on StackGuardian, state is managed by the platform; locally, it is a file in the directory.

## Learn more

- [Workflows](https://docs.stackguardian.io/docs/deploy/workflows/overview/)
- [Library and templates](https://docs.stackguardian.io/docs/develop/library/overview/)
- [Policies](https://docs.stackguardian.io/docs/develop/policies/overview/)
- [Tirith](https://github.com/StackGuardian/tirith)

## License

[Apache License 2.0](LICENSE)
