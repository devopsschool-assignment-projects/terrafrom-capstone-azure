#!/usr/bin/env bash
# Checks that the deployed application really works:   ./scripts/validate.sh student03
set -uo pipefail
STUDENT="${1:?usage: validate.sh <student-id>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/_env.sh"
export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
export TF_DATA_DIR="$ROOT/.tf-data/${STUDENT}"   # separate working data per student
cd "$ROOT/infra"
terraform init -input=false -reconfigure -backend-config="$ROOT/config/backend.hcl" -backend-config="key=${STUDENT}.tfstate" >/dev/null
IP=$(terraform output -raw app_public_ip)
URL=$(terraform output -raw app_url)
HOST=${URL#http://}
RG=$(terraform output -raw resource_group)
CLUSTER=$(terraform output -raw aks_cluster)

fail=0
pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
flunk() { printf "  \033[31mFAIL\033[0m  %s\n" "$1"; fail=1; }
http() { curl -s -m 15 -o /tmp/val.$$ -w '%{http_code}' "$@"; }

echo "Validating ${STUDENT}: ${URL}  (gateway IP ${IP})"

echo "1. Cluster"
az aks get-credentials -g "$RG" -n "$CLUSTER" --admin --overwrite-existing >/dev/null 2>&1
NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready')
[ "$NODES" -ge 1 ] && pass "$NODES worker node(s) Ready" || flunk "no Ready node"
for app in postgres backend frontend; do
  R=$(kubectl -n capstone get pods -l app=$app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  [ "$R" = "true" ] && pass "$app pod is Ready" || flunk "$app pod is not Ready"
done
PVC=$(kubectl -n capstone get pvc -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
[ "$PVC" = "Bound" ] && pass "database disk (PVC) is Bound" || flunk "database disk is not Bound ($PVC)"

echo "2. DNS"
RES=$(dig +short @1.1.1.1 "$HOST" | head -1)
if [ "$RES" = "$IP" ]; then pass "$HOST resolves to $IP"; USE_DNS=1; else flunk "$HOST resolves to '${RES:-nothing}' (expected $IP) - delegation may still be propagating"; USE_DNS=0; fi

echo "3. Web app (through Application Gateway + WAF)"
if [ $USE_DNS -eq 1 ]; then BASE="http://$HOST"; CURLOPT=(); else BASE="http://$IP"; CURLOPT=(-H "Host: $HOST"); fi
CODE=$(http ${CURLOPT[@]+"${CURLOPT[@]}"} "$BASE/"); [ "$CODE" = "200" ] && pass "GET / -> 200" || flunk "GET / -> $CODE"
CODE=$(http ${CURLOPT[@]+"${CURLOPT[@]}"} "$BASE/api/health"); [ "$CODE" = "200" ] && pass "GET /api/health -> 200 (backend + database up)" || flunk "GET /api/health -> $CODE"
http ${CURLOPT[@]+"${CURLOPT[@]}"} "$BASE/api/info" >/dev/null
SRC=$(jq -r .banner_source /tmp/val.$$ 2>/dev/null); [ "$SRC" = "key-vault" ] && pass "banner read from Key Vault via Entra ID workload identity" || flunk "banner source is '$SRC' ($(jq -r .banner_error /tmp/val.$$ 2>/dev/null))"
MSG="validate-$(date +%s)"
CODE=$(http ${CURLOPT[@]+"${CURLOPT[@]}"} -X POST -H 'Content-Type: application/json' -d "{\"author\":\"validate\",\"text\":\"$MSG\"}" "$BASE/api/messages"); [ "$CODE" = "201" ] && pass "POST message -> 201 (written to PostgreSQL)" || flunk "POST message -> $CODE"
http ${CURLOPT[@]+"${CURLOPT[@]}"} "$BASE/api/messages" >/dev/null
grep -q "$MSG" /tmp/val.$$ && pass "message read back from the database" || flunk "message not found when reading back"

echo "4. WAF blocks attacks"
CODE=$(http ${CURLOPT[@]+"${CURLOPT[@]}"} "$BASE/?q=<script>alert(1)</script>"); [ "$CODE" = "403" ] && pass "XSS attempt blocked by WAF (403)" || flunk "XSS attempt returned $CODE (expected 403; is waf_mode Detection?)"

rm -f /tmp/val.$$
echo
[ $fail -eq 0 ] && echo "ALL CHECKS PASSED  ->  open $URL" || { echo "Some checks failed - see docs/TROUBLESHOOTING.md"; exit 1; }
