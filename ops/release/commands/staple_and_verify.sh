#!/usr/bin/env bash
# staple_and_verify.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

log_step "STEP 4: Stapling and verifying DMG"

ensure_command xcrun
ensure_command spctl

[[ -f "$DMG_OUTPUT" ]] || die "DMG not found: $DMG_OUTPUT"

xcrun stapler staple "$DMG_OUTPUT"
spctl -a -t open --context context:primary-signature -v "$DMG_OUTPUT"

log_success "DMG is stapled and ready: $DMG_OUTPUT"
