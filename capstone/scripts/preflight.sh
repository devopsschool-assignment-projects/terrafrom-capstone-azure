#!/usr/bin/env bash
# Checks everything a student needs BEFORE running terraform.
#   ./scripts/preflight.sh student03
set -uo pipefail
STUDENT="${1:?usage: preflight.sh <student-id>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/_env.sh"
fail=0
ok()   { printf "  \033[32mOK\033[0m    %s\n" "$1"; }
bad()  { printf "  \033[31mFAIL\033[0m  %s\n" "$1"; fail=1; }

echo "Tools"
for t in az terraform kubectl jq curl dig; do
  command -v "$t" >/dev/null && ok "$t installed" || bad "$t is missing (see docs/INSTALL.md)"
done

echo "Azure login"
if SUB=$(az account show --query name -o tsv 2>/dev/null); then ok "logged in, subscription: $SUB"; else bad "not logged in - run: ./scripts/login.sh  (or ./scripts/login.sh sp)"; fi

echo "Master values"
if python3 - "$ROOT/config/master-values.yaml" "$STUDENT" <<'PY'
import sys, re
text = open(sys.argv[1]).read()
sys.exit(0 if re.search(rf"^\s{{2}}{re.escape(sys.argv[2])}:", text, re.M) else 1)
PY
then ok "'$STUDENT' is listed in config/master-values.yaml"; else bad "'$STUDENT' is NOT in config/master-values.yaml"; fi

echo "Terraform state backend"
[ -f "$ROOT/config/backend.hcl" ] && ok "config/backend.hcl found" || bad "config/backend.hcl missing - ask the instructor"

echo "Cloudflare token"
if grep -qE '^\s+enable_cloudflare_delegation:\s*true' "$ROOT/config/master-values.yaml"; then
  if [ -n "${TF_VAR_cloudflare_api_token:-}" ]; then
    ok "Cloudflare token found (config/secrets.env)"
  else
    bad "no Cloudflare token: add CLOUDFLARE_API_TOKEN to config/secrets.env"
  fi
else
  ok "Cloudflare delegation disabled (use the gateway IP)"
fi

echo "Quota (westus3)"
LOC=$(grep -E '^\s+location:' "$ROOT/config/master-values.yaml" | head -1 | awk '{print $2}')
USAGE=$(az vm list-usage -l "$LOC" -o json 2>/dev/null)
if [ -n "$USAGE" ]; then
  FREE=$(echo "$USAGE" | jq -r '.[] | select(.name.value=="StandardDsv6Family") | (.limit|tonumber) - (.currentValue|tonumber)')
  [ "${FREE:-0}" -ge 2 ] && ok "Dsv6 vCPUs free: $FREE (need 2)" || bad "not enough Dsv6 vCPU quota (free: ${FREE:-0}, need 2)"
  PIPS=$(az network list-usages -l "$LOC" -o json 2>/dev/null | jq -r '.[] | select(.name.value=="IPv4StandardSkuPublicIpAddresses") | (.limit|tonumber) - (.currentValue|tonumber)')
  [ "${PIPS:-0}" -ge 2 ] && ok "Public IPs free: $PIPS (need 2)" || bad "not enough public IP quota (free: ${PIPS:-0}, need 2)"
fi

echo
[ $fail -eq 0 ] && echo "All checks passed - run ./scripts/deploy.sh $STUDENT" || { echo "Fix the FAIL items above, then run again."; exit 1; }
