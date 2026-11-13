#!/usr/bin/env bash
# Publish the dashboard's current Quick Tunnel address to tunnel.json (GitHub Pages)
# when it changes, so https://wock9000.github.io/sushi-arb/ always reaches the dashboard.
# Run by sab-link-update.timer every minute. Publishes only an address that serves 200.
set -euo pipefail
cd "$(dirname "$0")"
host=$(curl -sf --max-time 5 http://127.0.0.1:8795/quicktunnel | jq -r '.hostname // empty')
[ -n "$host" ] || { echo "tunnel metrics unavailable"; exit 0; }
url="https://$host"
current=$(jq -r '.url // empty' tunnel.json 2>/dev/null || true)
[ "$url" = "$current" ] && exit 0
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$url/" || true)
[ "$code" = 200 ] || { echo "new address $url answers $code; not publishing yet"; exit 0; }
printf '{"url":"%s","updated":"%s"}\n' "$url" "$(date -u +%FT%TZ)" > tunnel.json
git add tunnel.json
git -c user.name=wock -c user.email=55965962+wock9000@users.noreply.github.com \
  commit -q -m "tunnel: $host"
PRE_PUSH_SKIP_REPO_CENSUS=1 git push -q origin main
echo "published $url"
