#!/usr/bin/env bash
# Deploys one student's whole environment:   ./scripts/deploy.sh student03
# Takes about 15 minutes.
set -euo pipefail
STUDENT="${1:?usage: deploy.sh <student-id>   e.g. deploy.sh student03}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/_env.sh"

"$ROOT/scripts/preflight.sh" "$STUDENT"

export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
export TF_DATA_DIR="$ROOT/.tf-data/${STUDENT}"   # separate working data per student
cd "$ROOT/infra"

terraform init -input=false -reconfigure \
  -backend-config="$ROOT/config/backend.hcl" \
  -backend-config="key=${STUDENT}.tfstate"

PLAN_FILE="$TF_DATA_DIR/${STUDENT}.tfplan"
terraform plan -input=false -var "student_id=${STUDENT}" -out="$PLAN_FILE"
echo
echo "Applying the plan above (about 15 minutes)..."
terraform apply -input=false "$PLAN_FILE"
rm -f "$PLAN_FILE"

echo
echo "Done. Now run:  ./scripts/validate.sh ${STUDENT}"
