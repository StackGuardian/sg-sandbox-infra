#!/bin/sh
# Post-deploy rollout check, run by OpenTofu/Terraform as a local-exec provisioner.
#
# Inputs (environment):
#   SERVICE              name shown in the log
#   HEALTHY_TARGETS      targets reporting healthy after the rollout
#   MIN_HEALTHY_TARGETS  minimum required to call the rollout good
#
# Exits non-zero when the rollout is unhealthy, which fails the apply and taints
# the check, so the next apply runs it again.
set -eu

service="${SERVICE:-service}"
healthy="${HEALTHY_TARGETS:?HEALTHY_TARGETS is required}"
minimum="${MIN_HEALTHY_TARGETS:?MIN_HEALTHY_TARGETS is required}"

case "$healthy$minimum" in
  *[!0-9]*)
    echo "verify-rollout: HEALTHY_TARGETS and MIN_HEALTHY_TARGETS must be whole numbers" >&2
    exit 2
    ;;
esac

echo "verify-rollout: ${service}: ${healthy} healthy target(s), ${minimum} required"

if [ "$healthy" -lt "$minimum" ]; then
  echo "verify-rollout: ${service}: rollout unhealthy (${healthy}/${minimum}), failing the apply" >&2
  exit 1
fi

echo "verify-rollout: ${service}: rollout healthy"
