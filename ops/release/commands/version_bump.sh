#!/usr/bin/env bash
# version_bump.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

log_step "STEP 0.1: Bumping build number"

new_build_number="$(current_build_id)"
new_version="${APP_VERSION}+${new_build_number}"

log_info "Updating pubspec.yaml -> $new_version"
sed_inplace "s/^version: .*/version: $new_version/" "$PROJECT_ROOT/pubspec.yaml"

echo "##vso[task.setvariable variable=APP_VERSION]$APP_VERSION"
echo "##vso[task.setvariable variable=APP_VERSION_FULL]$new_version"
echo "##vso[task.setvariable variable=BUILD_NUMBER]$new_build_number"

log_success "Version updated to $new_version"
