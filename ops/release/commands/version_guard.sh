#!/usr/bin/env bash
# version_guard.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

branch_name="$(current_branch_name)"

if [[ "$branch_name" == release/* ]]; then
  version_from_branch="${branch_name#release/}"

  log_info "Validating release branch version ($version_from_branch) vs pubspec semantic version ($APP_VERSION)"

  if [[ "$version_from_branch" != "$APP_VERSION" ]]; then
    die "Version mismatch: branch=$version_from_branch pubspec=$APP_VERSION"
  fi

  log_success "Version guard passed"
else
  log_info "Skipping version guard on non-release branch: $branch_name"
fi
