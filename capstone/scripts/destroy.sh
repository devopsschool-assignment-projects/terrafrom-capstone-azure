#!/usr/bin/env bash
# Removes everything for one student (and stops the billing):  ./scripts/destroy.sh student03
set -euo pipefail
STUDENT="${1:?usage: destroy.sh <student-id>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/_env.sh"
export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
export TF_DATA_DIR="$ROOT/.tf-data/${STUDENT}"   # separate working data per student
cd "$ROOT/infra"

terraform init -input=false -reconfigure \
  -backend-config="$ROOT/config/backend.hcl" \
  -backend-config="key=${STUDENT}.tfstate"

terraform destroy -input=false -auto-approve -var "student_id=${STUDENT}"
echo "Everything for ${STUDENT} has been deleted."
