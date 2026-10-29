#!/bin/sh
# Post-apply hook: prints the notice a team would send after a deploy. It is a
# mock: nothing is sent anywhere.
#
# StackGuardian runs lifecycle hooks with /bin/sh -c from the runner's own
# directory, not the stack's, so call it by the stack's path:
#   sh "$LOCAL_IAC_SOURCE_CODE_DIR/../../scripts/post-apply-notify.sh"
#
# Writes to stdout only and always exits 0.
exec 2>&1

stack_dir="${LOCAL_IAC_SOURCE_CODE_DIR:-$(pwd)}"
stack="$(basename "$stack_dir")"
when="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

echo "post-apply-notify: ${stack} applied at ${when}"
echo "post-apply-notify: would post to the #deployments channel (mock, nothing sent)"

exit 0
