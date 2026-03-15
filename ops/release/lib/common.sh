#!/usr/bin/env bash
# common.sh

set -euo pipefail
IFS=$'\n\t'

log_step()    { printf '\n\033[1;33m🔹 %s\033[0m\n' "$*"; }
log_info()    { printf 'ℹ️  %s\n' "$*"; }
log_warn()    { printf '\033[1;33m⚠️  %s\033[0m\n' "$*"; }
log_error()   { printf '\033[0;31m❌ %s\033[0m\n' "$*" >&2; }
log_success() { printf '\033[0;32m✅ %s\033[0m\n' "$*"; }

die() {
  log_error "$*"
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_command() {
  local cmd="$1"
  command_exists "$cmd" || die "Required command not found: $cmd"
}

safe_mkdir() {
  mkdir -p "$@"
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

sed_inplace() {
  local expr="$1"
  local file="$2"

  if is_macos; then
    sed -i '' "$expr" "$file"
  else
    sed -i "$expr" "$file"
  fi
}

normalize_bool() {
  local value="${1:-false}"
  value="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  [[ "$value" == "1" || "$value" == "true" || "$value" == "yes" || "$value" == "y" ]]
}

join_by() {
  local delimiter="$1"
  shift || true
  local first=1
  for item in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf '%s' "$item"
      first=0
    else
      printf '%s%s' "$delimiter" "$item"
    fi
  done
}
