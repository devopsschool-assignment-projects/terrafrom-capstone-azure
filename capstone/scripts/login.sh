#!/usr/bin/env bash
# Sign in to Azure. Two ways - use whichever your instructor tells you:
#
#   ./scripts/login.sh        Way 1: interactive. Opens a code + link; you sign in in the
#                             browser and approve MFA if asked. Use your own account or the lab account.
#   ./scripts/login.sh sp     Way 2: service principal (app id + secret). No browser, no MFA.
#                             Values come from config/secrets.env (see the .example file)
#                             or from AZURE_CLIENT_ID / AZURE_CLIENT_SECRET / AZURE_TENANT_ID.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-interactive}"

case "$MODE" in
  interactive|i)
    az login --use-device-code --only-show-errors >/dev/null
    ;;
  sp|service-principal)
    ENV_FILE="$ROOT/config/secrets.env"
    if [ -f "$ENV_FILE" ]; then
      # shellcheck disable=SC1090
      set -a; source "$ENV_FILE"; set +a
    fi
    : "${AZURE_CLIENT_ID:?AZURE_CLIENT_ID is not set (see config/secrets.env.example)}"
    : "${AZURE_CLIENT_SECRET:?AZURE_CLIENT_SECRET is not set (see config/secrets.env.example)}"
    : "${AZURE_TENANT_ID:?AZURE_TENANT_ID is not set (see config/secrets.env.example)}"
    az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" --only-show-errors >/dev/null
    ;;
  *)
    echo "usage: login.sh [interactive|sp]" >&2; exit 2 ;;
esac

[ -n "${AZURE_SUBSCRIPTION_ID:-}" ] && az account set --subscription "$AZURE_SUBSCRIPTION_ID"
echo "Signed in:"
az account show --query "{user:user.name, subscription:name}" -o table
