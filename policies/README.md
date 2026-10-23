# Policies

Two policies written in [Tirith](https://github.com/StackGuardian/tirith), StackGuardian's open-source policy framework. Both read the Terraform/OpenTofu plan (`stackguardian/terraform_plan` provider), so they run after plan and before apply.

| File | What it checks | Action when it fails | Applies to |
|---|---|---|---|
| [`approve-destructive-changes.json`](approve-destructive-changes.json) | Any planned `delete` action on a `terraform_data` resource. A replace is planned as delete plus create, so replacements count too | Approval required: the run waits until an approver signs off. One rejection cancels it | Workflow group `platform-prod` |
| [`deny-public-ingress.json`](deny-public-ingress.json) | Every resource whose `input.public_ingress` is set must have it `false` | Fail: the run stops | Workflow group `platform-ops` |

The scope, the action and the approvers are set on the StackGuardian policy, not in these files. These files hold only the rule body.

## How the rules read the plan

- **`approve-destructive-changes`** uses `operation_type: action` on `terraform_data`, the resource type that models the infrastructure here. The `null_resource` that runs the rollout check is replaced whenever a new image is deployed, so it is left out; otherwise every rollout would wait for approval. The rule looks at each entry in `resource_changes[].change.actions` and fails on `delete`. `create`, `update` and `no-op` pass.
- **`deny-public-ingress`** uses `operation_type: attribute` with the dotted path `input.public_ingress`. The mock resources in this repo are `terraform_data`, and each one carries its settings in `input`, so the rule reads that attribute the way it would read a real resource's attribute.
- Both rules set `error_tolerance: 2`. A plan with no changes, or a resource without the attribute (for example a `null_resource`), is skipped instead of failing the rule.

## Try it locally

```sh
pip install 'git+https://github.com/StackGuardian/tirith.git@1.2.1'

cd stacks/network
tofu init
tofu apply
tofu plan -var vpc_cidr=10.41.0.0/16 -out=plan.tfplan
tofu show -json plan.tfplan > plan.json

tirith -policy-path ../../policies/approve-destructive-changes.json -input-path plan.json
```

The `vpc_cidr` change replaces the network, so the approval rule fails, which on the platform holds the run for approval. With no `-var`, the plan has nothing to delete and the rule passes.

`tirith lint policies/` checks the policy files themselves; CI runs it on every pull request.
