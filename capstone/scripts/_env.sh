# Sourced by the other scripts. Reads the ONE secrets file (config/secrets.env, never committed)
# and gives Terraform the Cloudflare token. Safe to source when the file does not exist.
_ENV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_ENV_FILE="$_ENV_ROOT/config/secrets.env"
if [ -z "${TF_VAR_cloudflare_api_token:-}" ] && [ -f "$_ENV_FILE" ]; then
  _tok=$(grep -E '^CLOUDFLARE_API_TOKEN=' "$_ENV_FILE" | head -1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//')
  [ -n "$_tok" ] && export TF_VAR_cloudflare_api_token="$_tok"
  unset _tok
fi
