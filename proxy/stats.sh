#!/usr/bin/env bash
# Don't Fold — usage counters.
#   ./stats.sh
# Prints every counter the Worker records:
#   count:start:total          — challenges started, all time
#   count:complete:total       — challenges finished (reached a verdict)
#   count:start:day:YYYY-MM-DD  — started, per day
#   count:start:scenario:<id>  — started, per scenario
set -e
cd "$(dirname "$0")"
NS="d9c460e08e8a46b3a635161de9fd4189"

NAMES=$(npx --no-install wrangler kv key list --namespace-id="$NS" --remote 2>/dev/null \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{JSON.parse(s).map(k=>k.name).filter(n=>n.startsWith("count:")).sort().forEach(n=>console.log(n))}catch(e){}})')

if [ -z "$NAMES" ]; then echo "No counters yet."; exit 0; fi

echo "── Don't Fold usage ──"
for k in $NAMES; do
  v=$(npx --no-install wrangler kv key get "$k" --namespace-id="$NS" --remote 2>/dev/null)
  printf "%-44s %s\n" "$k" "$v"
done
