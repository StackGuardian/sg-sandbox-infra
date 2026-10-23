#!/usr/bin/env bash
# Generic hygiene scan for a public repo. Checks tracked files and every commit
# message for cloud account IDs, StackGuardian API keys, real email addresses,
# Slack links and AWS access keys.
#
# It prints where a match is and which rule matched, never the matched text,
# so a hit is not repeated into public CI logs.
#
# Usage: scripts/hygiene-scan.sh [repo-dir]   Exit 0 when clean, 1 on any hit.
set -euo pipefail

cd "${1:-$(git rev-parse --show-toplevel)}"

# Rules: name, pattern and allow-list (all ERE). A line is a hit when the
# pattern still matches after every allowed match is removed from it.
names=(
  aws-account-id
  sg-api-key
  email
  slack-link
  aws-access-key
)
patterns=(
  '(^|[^0-9A-Za-z])[0-9]{12}([^0-9A-Za-z]|$)'
  'sg[ou]_[A-Za-z0-9]{8,}'
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  '([a-z0-9-]+\.)?slack\.com/'
  '(AKIA|ASIA)[0-9A-Z]{16}'
)
allows=(
  '(0{12}|12345678901[2])'
  ''
  '[A-Za-z0-9._%+-]+@(example\.(com|org|net)|users\.noreply\.github\.com)|noreply@github\.com'
  ''
  ''
)

hits=0

is_hit() {
  # $1 text, $2 pattern, $3 allow
  local text="$1"
  if [ -n "$3" ]; then
    text="$(printf '%s\n' "$text" | sed -E "s/$3//g")"
  fi
  printf '%s\n' "$text" | grep -Eq -e "$2"
}

for i in "${!names[@]}"; do
  name="${names[$i]}"
  pattern="${patterns[$i]}"
  allow="${allows[$i]}"

  # Tracked files: git grep prints file:line:text
  while IFS= read -r line; do
    file="${line%%:*}"
    rest="${line#*:}"
    lineno="${rest%%:*}"
    text="${rest#*:}"
    if is_hit "$text" "$pattern" "$allow"; then
      echo "hygiene: $name in $file:$lineno" >&2
      hits=$((hits + 1))
    fi
  done < <(git grep -n -I -E -e "$pattern" -- . ':(exclude)scripts/hygiene-scan.sh' || true)

  # Commit messages across all refs
  while IFS= read -r sha; do
    while IFS= read -r text; do
      if is_hit "$text" "$pattern" "$allow"; then
        echo "hygiene: $name in the message of commit ${sha:0:12}" >&2
        hits=$((hits + 1))
        break
      fi
    done < <(git log -1 --format=%B "$sha" | grep -E -e "$pattern" || true)
  done < <(git rev-list --all)
done

if [ "$hits" -gt 0 ]; then
  echo "hygiene: $hits hit(s). Remove them; if a commit message is affected, rewrite it before pushing." >&2
  exit 1
fi
echo "hygiene: clean"
