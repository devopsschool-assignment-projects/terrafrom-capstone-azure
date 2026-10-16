#!/usr/bin/env bash
# Builds the frontend + backend images inside Azure Container Registry and
# copies the PostgreSQL image into it.  Called by Terraform (infra/main.tf);
# you can also run it by hand:  ./scripts/build-images.sh <acr-name> <tag> [postgres-image]
set -euo pipefail

ACR="${1:?usage: build-images.sh <acr-name> <tag> [postgres-image]}"
TAG="${2:?usage: build-images.sh <acr-name> <tag> [postgres-image]}"
PG_IMAGE="${3:-postgres:16-alpine}"
APP_DIR="$(cd "$(dirname "$0")/../app" && pwd)"

echo "==> Copying ${PG_IMAGE} into ${ACR}"
az acr import --name "$ACR" --source "docker.io/library/${PG_IMAGE}" --image "${PG_IMAGE}" --force --only-show-errors

build() {  # build <name> <folder>
  local name="$1" dir="$2"
  echo "==> Building ${name}:${TAG} in ACR"
  if az acr build --registry "$ACR" --image "${name}:${TAG}" "$dir" --no-logs --only-show-errors 2>/tmp/acr-build-$$.err; then
    return 0
  fi
  if grep -q "TasksOperationsNotAllowed" /tmp/acr-build-$$.err; then
    echo "    ACR Tasks not allowed on this subscription - building with local Docker instead"
    command -v docker >/dev/null || { echo "Docker is required for the fallback build"; exit 1; }
    az acr login --name "$ACR" --only-show-errors
    local ref="${ACR}.azurecr.io/${name}:${TAG}"
    docker build --platform linux/amd64 -t "$ref" "$dir"
    docker push "$ref"
  else
    cat /tmp/acr-build-$$.err >&2
    exit 1
  fi
}

build capstone-backend  "${APP_DIR}/backend"
build capstone-frontend "${APP_DIR}/frontend"
echo "==> Images ready in ${ACR}"
