#!/usr/bin/env bash
# Plans the prod stacks and checks both policies against the plan JSON with
# Tirith: default plans pass both, public_ingress fails deny-public-ingress,
# a database replace needs approval, an image update does not.
#
# Needs tofu, tirith and jq on PATH. Works on a temporary copy, so the repo
# itself is never touched.
#
# Usage: scripts/policy-check.sh [repo-dir]   Exit 0 when every check holds.
set -uo pipefail

repo="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "$repo/stacks" "$repo/modules" "$repo/scripts" "$repo/policies" "$work/"

export TF_IN_AUTOMATION=1 TF_INPUT=0
export TF_VAR_api_token="${TF_VAR_api_token:-policy-check-placeholder}"

failures=0

# result <policy> <plan.json>: prints true, false or null
result() {
  tirith -policy-path "$work/policies/$1.json" -input-path "$2" --json | jq -r '.final_result'
}

expect() {
  # expect <policy> <plan.json> <true|false> <label>
  local got
  got="$(result "$1" "$2")"
  if [ "$got" = "$3" ]; then
    echo "ok    $4: $1 = $got"
  else
    echo "FAIL  $4: $1 = $got, expected $3"
    failures=$((failures + 1))
  fi
}

plan_json() {
  # plan_json <stack-dir> <out.json> [VAR=value ...]
  local dir="$1" out="$2"
  shift 2
  (cd "$dir" && env "$@" tofu plan -no-color -out=check.tfplan >/dev/null && tofu show -json check.tfplan >"$out")
}

for stack in network service shared-network secrets-demo; do
  dir="$work/stacks/$stack"
  (cd "$dir" && tofu init -no-color >/dev/null) || { echo "FAIL  $stack: init"; failures=$((failures + 1)); continue; }
  plan_json "$dir" "$work/$stack-default.json"
  expect deny-public-ingress "$work/$stack-default.json" true "$stack default"
  expect approve-destructive-changes "$work/$stack-default.json" true "$stack default"
done

svc="$work/stacks/service"
plan_json "$svc" "$work/public.json" TF_VAR_public_ingress=true
expect deny-public-ingress "$work/public.json" false "service public_ingress=true"
# Same plan with the resources in reverse order: the result must not depend on it.
jq '.resource_changes |= reverse' "$work/public.json" >"$work/public-reversed.json"
expect deny-public-ingress "$work/public-reversed.json" false "service public_ingress=true, reversed"

(cd "$svc" && tofu apply -no-color -auto-approve >/dev/null) || { echo "FAIL  service: apply"; failures=$((failures + 1)); }
plan_json "$svc" "$work/db16.json" TF_VAR_db_engine_version=16
expect approve-destructive-changes "$work/db16.json" false "service db_engine_version=16"
expect deny-public-ingress "$work/db16.json" true "service db_engine_version=16"
plan_json "$svc" "$work/image.json" TF_VAR_image_tag=1.43.0
expect approve-destructive-changes "$work/image.json" true "service image_tag update"
expect deny-public-ingress "$work/image.json" true "service image_tag update"

if [ "$failures" -gt 0 ]; then
  echo "policy-check: $failures failure(s)"
  exit 1
fi
echo "policy-check: all checks passed"
