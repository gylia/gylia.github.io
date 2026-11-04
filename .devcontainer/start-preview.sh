#!/usr/bin/env bash
# Start the live preview. -D includes drafts, which is the whole point for notes.
set -uo pipefail
cd "$(dirname "$0")/.."

pkill -f "hugo server" 2>/dev/null || true

BASE=""
if [ -n "${CODESPACE_NAME:-}" ]; then
  BASE="--baseURL https://${CODESPACE_NAME}-1313.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN} --appendPort=false"
fi

nohup hugo server -D --bind 0.0.0.0 --port 1313 $BASE \
  > /tmp/hugo-preview.log 2>&1 &

sleep 3
echo "Preview running on port 1313. Drafts included."
echo "Log: /tmp/hugo-preview.log"
