#!/bin/sh
# Pre-init hook: prints the run context before OpenTofu starts.
#
# StackGuardian runs lifecycle hooks with /bin/sh -c from the runner's own
# directory, not the stack's, so call it by the stack's path:
#   sh "$LOCAL_IAC_SOURCE_CODE_DIR/../../scripts/pre-plan-check.sh"
#
# Prints the names of TF_VAR_* switches, never their values. Writes to stdout
# only (stderr output fails drift runs) and always exits 0, so it never stops
# a run by itself.
exec 2>&1

stack_dir="${LOCAL_IAC_SOURCE_CODE_DIR:-$(pwd)}"
stack="$(basename "$stack_dir")"

echo "pre-plan-check: stack ${stack}"

if command -v tofu >/dev/null; then
  echo "pre-plan-check: engine $(tofu version 2>&1 | head -n 1)"
fi

switches="$(env | sed -n 's/^\(TF_VAR_[A-Za-z0-9_]*\)=.*/\1/p' | sort | tr '\n' ' ' | sed 's/ $//')"
if [ -n "$switches" ]; then
  echo "pre-plan-check: variables set from the environment: ${switches}"
else
  echo "pre-plan-check: no TF_VAR_* variables in the environment, using defaults"
fi

if [ "${TF_VAR_change_freeze:-false}" = "true" ]; then
  echo "pre-plan-check: change_freeze is on, so the plan will stop at the release guard"
fi

exit 0
