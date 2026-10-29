#!/usr/bin/env bash
# shellcheck disable=SC2329 # verify_* and leftovers_* are called by name
# Deploys one template for real, checks it works, destroys it and checks that
# nothing tagged with it is left behind. Creates real (small) cloud resources.
#
# Credentials come only from the environment:
#   aws-*    AWS_PROFILE or AWS_* env (region comes from the template default)
#   azure-*  az CLI login; ARM_SUBSCRIPTION_ID is read from `az account show` if unset
#   gcp-*    gcloud application-default login and TF_VAR_project_id
#
# aws-k3s also installs the k3s-helm-release chart on the new cluster with the
# kubeconfig output (the same path the second workflow takes), then removes it.
#
# Works on a temporary copy of the template. Destroy runs on failure or Ctrl-C
# unless --keep is given.
#
# Usage: scripts/template-test.sh <template> [--keep] [-var name=value ...]
set -uo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tpl="${1:?usage: scripts/template-test.sh <template> [--keep] [-var name=value ...]}"
shift
keep=0
tf_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) keep=1 ;;
    -var) tf_args+=(-var "$2"); shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

src="$repo/templates/$tpl"
[ -d "$src" ] || { echo "no such template: $src" >&2; exit 2; }
case "$tpl" in
  aws-*) cloud=aws ;;
  azure-*) cloud=azure ;;
  gcp-*) cloud=gcp ;;
  *) echo "$tpl is not an OpenTofu cloud template (aws-*, azure-*, gcp-*)" >&2; exit 2 ;;
esac

work="$(mktemp -d)"
cp -R "$src/." "$work/"
cd "$work" || exit 1
export TF_IN_AUTOMATION=1 TF_INPUT=0

case "$cloud" in
  azure)
    if [ -z "${ARM_SUBSCRIPTION_ID:-}" ]; then
      ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)" || exit 1
      export ARM_SUBSCRIPTION_ID
    fi
    ;;
  gcp)
    [ -n "${TF_VAR_project_id:-}" ] || { echo "set TF_VAR_project_id" >&2; exit 2; }
    ;;
esac

start=$(date +%s)
applied=0 destroyed=0 failed=0

say() { printf '\n== %s (%ss)\n' "$*" "$(( $(date +%s) - start ))"; }
fail() { echo "FAIL  $*"; failed=1; }
out() { tofu output -raw "$1"; }

destroy() {
  say "destroy"
  if tofu destroy -auto-approve -no-color "${tf_args[@]}" >destroy.log 2>&1; then
    destroyed=1
    grep -E '^Destroy complete' destroy.log
  else
    tail -n 30 destroy.log
    fail "destroy failed; state kept in $work"
  fi
}

cleanup() {
  if [ "$applied" = 1 ] && [ "$destroyed" = 0 ]; then
    if [ "$keep" = 1 ]; then
      echo "kept: state and copy in $work (run tofu destroy there)"
      return
    fi
    destroy
  fi
  if [ "$destroyed" = 1 ] || [ "$applied" = 0 ]; then
    [ "$failed" = 0 ] && rm -rf "$work" || echo "logs kept in $work"
  fi
}
trap cleanup EXIT
trap 'echo "interrupted"; failed=1; exit 130' INT TERM

# ---- verify, one function per template --------------------------------------

verify_aws-s3-bucket() {
  local b
  b="$(out bucket_name)"
  aws s3api head-bucket --bucket "$b" || return 1
  aws s3api get-bucket-encryption --bucket "$b" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text
  echo "template-test" | aws s3 cp - "s3://$b/template-test.txt" --only-show-errors || return 1
  aws s3 cp "s3://$b/template-test.txt" - || return 1
}

verify_aws-ec2-vm() {
  local id
  id="$(out instance_id)"
  aws ec2 wait instance-running --instance-ids "$id" || return 1
  aws ec2 describe-instances --instance-ids "$id" \
    --query 'Reservations[0].Instances[0].[InstanceType,State.Name,MetadataOptions.HttpTokens]' --output text
  # SSM registration takes a few minutes; report it but don't fail on it.
  local ping=""
  for _ in $(seq 1 18); do
    ping="$(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$id" \
      --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null)"
    [ "$ping" = Online ] && break
    sleep 10
  done
  echo "ssm: ${ping:-none}"
}

verify_aws-k3s() {
  local kc="$work/kubeconfig"
  out kubeconfig_b64 | base64 -d >"$kc" || return 1
  chmod 600 "$kc"
  for _ in $(seq 1 30); do
    kubectl --kubeconfig "$kc" get nodes 2>/dev/null | grep -q ' Ready ' && break
    sleep 10
  done
  kubectl --kubeconfig "$kc" get nodes -o wide || return 1
  kubectl --kubeconfig "$kc" get nodes | grep -q ' Ready ' || return 1

  # Second-step path: install the helm release template with this kubeconfig.
  local rel="$repo/templates/k3s-helm-release"
  if [ -f "$rel/Chart.yaml" ]; then
    say "helm release (k3s-helm-release)"
    # Copy the wrapper chart so --dependency-update doesn't write into the repo.
    cp -R "$rel" "$work/k3s-helm-release"
    helm --kubeconfig "$kc" upgrade --install podinfo "$work/k3s-helm-release" --dependency-update \
      --namespace podinfo --create-namespace --atomic --wait --timeout 5m || return 1
    kubectl --kubeconfig "$kc" -n podinfo rollout status deploy --timeout 120s || return 1
    kubectl --kubeconfig "$kc" -n podinfo get deploy,pods,svc || return 1
    helm --kubeconfig "$kc" uninstall podinfo --namespace podinfo --wait || return 1
  else
    echo "templates/k3s-helm-release/Chart.yaml not found; helm step skipped"
  fi
}

verify_azure-storage-account() {
  local rg sa
  rg="$(out resource_group_name)"
  sa="$(out storage_account_name)"
  az storage account show -g "$rg" -n "$sa" \
    --query '[kind,sku.name,minimumTlsVersion,allowBlobPublicAccess]' -o tsv || return 1
  az storage container-rm show -g "$rg" --storage-account "$sa" -n "$(out container_name)" \
    --query '[name,publicAccess]' -o tsv || return 1
}

verify_azure-linux-vm() {
  local rg
  rg="$(out resource_group_name)"
  az vm list -g "$rg" -d --query '[].[name,hardwareProfile.vmSize,powerState]' -o tsv || return 1
  az vm list -g "$rg" -d --query '[].powerState' -o tsv | grep -q 'VM running' || return 1
}

verify_gcp-gcs-bucket() {
  gcloud storage buckets describe "gs://$(out bucket_name)" --project "$TF_VAR_project_id" \
    --format='value(name,location,uniform_bucket_level_access,public_access_prevention)' || return 1
}

verify_gcp-e2-micro-vm() {
  local status
  status="$(gcloud compute instances describe "$(out instance_name)" --zone "$(out zone)" \
    --project "$TF_VAR_project_id" --format='value(status)')" || return 1
  echo "status: $status"
  [ "$status" = RUNNING ] || return 1
}

# ---- leftovers --------------------------------------------------------------

leftovers_aws() {
  local arns live a st
  for _ in 1 2 3 4 5 6; do
    arns="$(aws resourcegroupstaggingapi get-resources \
      --tag-filters "Key=sandbox-template,Values=$tpl" --query 'ResourceTagMappingList[].ResourceARN' --output text)"
    live=""
    for a in $arns; do
      case "$a" in
        arn:aws:ec2:*:instance/*)
          # Terminated instances keep their tags for a while.
          st="$(aws ec2 describe-instances --instance-ids "${a##*/}" \
            --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)"
          [ "$st" = terminated ] && continue
          ;;
      esac
      live="$live $a"
    done
    [ -z "$live" ] && { echo "none"; return 0; }
    sleep 20 # tagging API lags behind deletes
  done
  echo "left behind:$live"
  return 1
}

leftovers_azure() {
  if [ "$(az group exists -n "$rg_name")" = true ]; then
    echo "resource group $rg_name still exists"
    return 1
  fi
  echo "none"
}

leftovers_gcp() {
  local left=0
  case "$tpl" in
    gcp-gcs-bucket)
      gcloud storage buckets describe "gs://$bucket_name" --project "$TF_VAR_project_id" >/dev/null 2>&1 && { echo "bucket $bucket_name"; left=1; } ;;
    gcp-e2-micro-vm)
      gcloud compute instances describe "$instance_name" --zone "$zone" --project "$TF_VAR_project_id" >/dev/null 2>&1 && { echo "instance $instance_name"; left=1; }
      gcloud compute networks describe "$network_name" --project "$TF_VAR_project_id" >/dev/null 2>&1 && { echo "network $network_name"; left=1; } ;;
  esac
  [ "$left" = 0 ] && echo "none"
  return "$left"
}

# ---- run --------------------------------------------------------------------

say "init $tpl ($cloud)"
tofu init -input=false -no-color >init.log 2>&1 || { tail -n 30 init.log; fail "init"; exit 1; }

say "plan (stderr must be empty)"
tofu plan -input=false -no-color -out=tfplan "${tf_args[@]}" >plan.log 2>plan.err
rc=$?
grep -E '^Plan:' plan.log
if [ "$rc" != 0 ] || [ -s plan.err ]; then
  cat plan.err
  fail "plan (exit $rc, stderr $(wc -c <plan.err | tr -d ' ') bytes)"
  exit 1
fi

say "apply"
applied=1
if ! tofu apply -input=false -no-color tfplan >apply.log 2>&1; then
  tail -n 40 apply.log
  fail "apply"
  exit 1
fi
grep -E '^Apply complete' apply.log
tofu state list | wc -l | xargs echo "resources in state:"

# Keep the names the leftover check needs before the state goes away.
rg_name="$(out resource_group_name 2>/dev/null)"
bucket_name="$(out bucket_name 2>/dev/null)"
instance_name="$(out instance_name 2>/dev/null)"
zone="$(out zone 2>/dev/null)"
network_name="$(out network_name 2>/dev/null)"

say "verify"
if "verify_$tpl"; then echo "ok    verify"; else fail "verify"; fi

say "re-plan (expect no changes)"
tofu plan -input=false -no-color -detailed-exitcode "${tf_args[@]}" >replan.log 2>replan.err
case $? in
  0) echo "ok    no changes" ;;
  2) grep -E '^Plan:|will be|must be' replan.log | head -n 10; echo "note  re-plan shows changes" ;;
  *) cat replan.err; fail "re-plan" ;;
esac

if [ "$keep" = 1 ]; then
  say "kept (no destroy)"
  exit "$failed"
fi

destroy
[ "$destroyed" = 1 ] || exit 1

say "leftover check"
if "leftovers_$cloud"; then echo "ok    no leftovers"; else fail "leftovers"; fi

say "done: $tpl $([ "$failed" = 0 ] && echo PASS || echo FAIL)"
exit "$failed"
