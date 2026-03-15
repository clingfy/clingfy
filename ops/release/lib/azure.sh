#!/usr/bin/env bash
# azure.sh

require_azure_cli() {
  ensure_command az
}

az_blob_download_if_exists() {
  local account="$1"
  local container="$2"
  local blob_name="$3"
  local output_file="$4"

  local exists
  exists="$(
    az storage blob exists \
      --account-name "$account" \
      --container-name "$container" \
      --name "$blob_name" \
      --auth-mode login \
      --query exists -o tsv | tr '[:upper:]' '[:lower:]' | tr -d '\r\n '
  )"

  if [[ "$exists" != "true" ]]; then
    return 1
  fi

  az storage blob download \
    --account-name "$account" \
    --container-name "$container" \
    --name "$blob_name" \
    --file "$output_file" \
    --auth-mode login \
    --overwrite \
    --only-show-errors >/dev/null

  return 0
}

az_upload_blob() {
  local account="$1"
  local container="$2"
  local local_file="$3"
  local blob_name="$4"

  az storage blob upload \
    --account-name "$account" \
    --container-name "$container" \
    --file "$local_file" \
    --name "$blob_name" \
    --auth-mode login \
    --overwrite \
    --only-show-errors >/dev/null
}

purge_frontdoor_paths() {
  local resource_group="$1"
  local profile_name="$2"
  local endpoint_name="$3"
  local domain="$4"
  shift 4
  local content_paths=("$@")

  az afd endpoint purge \
    --resource-group "$resource_group" \
    --profile-name "$profile_name" \
    --endpoint-name "$endpoint_name" \
    --domains "$domain" \
    --content-paths "${content_paths[@]}"
}
