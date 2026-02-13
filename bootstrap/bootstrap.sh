#!/usr/bin/env bash
set -euo pipefail

# --- Git Bash / MSYS fix ---
# Prevent MSYS from rewriting args like /subscriptions/... into Windows paths (breaks RBAC scopes).
if [[ -n "${MSYSTEM:-}" ]]; then
  export MSYS2_ARG_CONV_EXCL="*"
  export MSYS_NO_PATHCONV=1
fi

# ===================== USER SETTINGS =====================
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-98fc1987-578b-4818-accb-bc58a1be0e45}"
TENANT_ID="${TENANT_ID:-cafd220b-657f-4eea-b87d-6351e3c2fcc2}"

GITHUB_OWNER="${GITHUB_OWNER:-YarochkinMichael}"
GITHUB_REPO="${GITHUB_REPO:-PinMyDay.Infra}"

ENV_DEV="${ENV_DEV:-dev}"
ENV_PROD="${ENV_PROD:-prod}"

LOCATION="${LOCATION:-westeurope}"     # Azure region name
REGION="${REGION:-we}"                # Your region suffix in names (we, ne, gwc, ...)

PROJECT="${PROJECT:-pmd}"
TYPE="${TYPE:-terraform}"
# =========================================================

# ---------- Naming convention ----------
# [resource]-[project]-[type]-[details: optional]-[region]
TFSTATE_RG="rg-${PROJECT}-${TYPE}-${REGION}"
TFSTATE_SA="sa${PROJECT}${TYPE}state${REGION}"
TFSTATE_CONTAINER="sc-${PROJECT}-${TYPE}-state-${REGION}"
APP_NAME="app-${PROJECT}-${TYPE}-ci-${REGION}"

TMPDIR="${TMPDIR:-/tmp}"
FC_DEV="${TMPDIR}/fc-${ENV_DEV}.json"
FC_PROD="${TMPDIR}/fc-${ENV_PROD}.json"
# =========================================================

handle_error() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || handle_error "'$cmd' is not installed or not on PATH."
}

ensure_login() {
  echo "==> Ensure login"
  if ! az account show >/dev/null 2>&1; then
    echo "    Not logged in. Starting Azure login..."
    if [[ -n "${MSYSTEM:-}" ]]; then
      az login --tenant "$TENANT_ID" --use-device-code >/dev/null
    else
      az login --tenant "$TENANT_ID" >/dev/null
    fi
  else
    echo "    Already logged in."
  fi

  echo "==> Select subscription: $SUBSCRIPTION_ID"
  az account set --subscription "$SUBSCRIPTION_ID"

  local active_sub
  active_sub="$(az account show --query id -o tsv 2>/dev/null || true)"
  [[ "$active_sub" == "$SUBSCRIPTION_ID" ]] || handle_error "Failed to set subscription. Active='$active_sub', expected='$SUBSCRIPTION_ID'."
}

ensure_provider_registered() {
  local provider="$1"

  echo "==> Ensure provider registered: $provider"
  az provider register --subscription "$SUBSCRIPTION_ID" -n "$provider" >/dev/null || true

  # Wait for registration (fast if already registered)
  while true; do
    local state
    state="$(az provider show --subscription "$SUBSCRIPTION_ID" -n "$provider" --query registrationState -o tsv 2>/dev/null || echo "")"
    [[ "$state" == "Registered" ]] && break
    echo "    Still registering... monitor with: az provider show -n $provider"
    sleep 3
  done
}

ensure_storage_account() {
  echo "==> Ensure tfstate storage account: $TFSTATE_SA"
  if az storage account show --subscription "$SUBSCRIPTION_ID" -g "$TFSTATE_RG" -n "$TFSTATE_SA" >/dev/null 2>&1; then
    echo "    Storage account exists."
  else
    az storage account create \
      --subscription "$SUBSCRIPTION_ID" \
      -n "$TFSTATE_SA" \
      -g "$TFSTATE_RG" \
      -l "$LOCATION" \
      --sku Standard_LRS \
      --kind StorageV2 >/dev/null
    echo "    Storage account created."
  fi
}

ensure_container() {
  echo "==> Ensure container: $TFSTATE_CONTAINER"
  local account_key
  account_key="$(az storage account keys list --subscription "$SUBSCRIPTION_ID" -g "$TFSTATE_RG" -n "$TFSTATE_SA" --query '[0].value' -o tsv)"
  az storage container create \
    --name "$TFSTATE_CONTAINER" \
    --account-name "$TFSTATE_SA" \
    --account-key "$account_key" >/dev/null
}

ensure_app_and_sp() {
  echo "==> Ensure App Registration: $APP_NAME"
  APP_ID="$(az ad app list --display-name "$APP_NAME" --query '[0].appId' -o tsv || true)"
  if [[ -z "${APP_ID:-}" || "${APP_ID:-null}" == "null" ]]; then
    APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
    echo "    App created."
  else
    echo "    App exists."
  fi

  echo "==> Ensure Service Principal"
  if az ad sp show --id "$APP_ID" >/dev/null 2>&1; then
    echo "    Service principal exists."
  else
    az ad sp create --id "$APP_ID" >/dev/null
    echo "    Service principal created."
  fi

  SP_OBJECT_ID="$(az ad sp show --id "$APP_ID" --query id -o tsv)"
}

ensure_role_assignment() {
  echo "==> Ensure Contributor role assignment on subscription"
  local scope="/subscriptions/$SUBSCRIPTION_ID"

  local has_role
  has_role="$(az role assignment list \
    --subscription "$SUBSCRIPTION_ID" \
    --assignee-object-id "$SP_OBJECT_ID" \
    --scope "$scope" \
    --role "Contributor" \
    --query "length([])" -o tsv 2>/dev/null || echo "0")"

  if [[ "$has_role" == "0" ]]; then
    az role assignment create \
      --subscription "$SUBSCRIPTION_ID" \
      --assignee-object-id "$SP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "Contributor" \
      --scope "$scope" >/dev/null
    echo "    Role assigned."
  else
    echo "    Role already assigned."
  fi
}

ensure_federated_cred() {
  local name="$1"
  local subject="$2"
  local file="$3"

  local exists
  exists="$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$name'] | length([])" -o tsv)"

  if [[ "$exists" == "0" ]]; then
    cat > "$file" <<JSON
{
  "name": "$name",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "$subject",
  "description": "OIDC for GitHub Actions $name",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
    az ad app federated-credential create --id "$APP_ID" --parameters "$file" >/dev/null
    echo "    Federated credential created: $name"
  else
    echo "    Federated credential exists: $name"
  fi
}

echo "==> Ensure Azure CLI installed"
require_cmd az

ensure_login

echo "==> Ensure tfstate resource group: $TFSTATE_RG"
az group create --subscription "$SUBSCRIPTION_ID" -n "$TFSTATE_RG" -l "$LOCATION" >/dev/null

ensure_provider_registered "Microsoft.Storage"
ensure_provider_registered "Microsoft.Authorization"

ensure_storage_account
ensure_container

ensure_app_and_sp
ensure_role_assignment

echo "==> Ensure federated credentials (GitHub OIDC)"
ensure_federated_cred \
  "github-env-${ENV_DEV}" \
  "repo:${GITHUB_OWNER}/${GITHUB_REPO}:environment:${ENV_DEV}" \
  "$FC_DEV"

ensure_federated_cred \
  "github-env-${ENV_PROD}" \
  "repo:${GITHUB_OWNER}/${GITHUB_REPO}:environment:${ENV_PROD}" \
  "$FC_PROD"

echo ""
echo "Bootstrap complete."
echo ""
echo "=== Put these in GitHub Actions Variables ==="
echo "AZURE_CLIENT_ID=$APP_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo ""
echo "=== Terraform backend config values ==="
echo "TFSTATE_RESOURCE_GROUP=$TFSTATE_RG"
echo "TFSTATE_STORAGE_ACCOUNT=$TFSTATE_SA"
echo "TFSTATE_CONTAINER=$TFSTATE_CONTAINER"
echo ""
echo "Next: create GitHub Environments: '$ENV_DEV' and '$ENV_PROD' (prod with approval)."
read -rp "Press enter to exit..."
