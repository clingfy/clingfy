#!/usr/bin/env bash
# notarize_dmg.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

log_step "STEP 3: Notarizing DMG $(date)"
require_notary_env

echo "NOTARY_KEY_PATH=$NOTARY_KEY_PATH"

set +e
submit_output="$(
  xcrun notarytool submit "$DMG_OUTPUT" \
    --key-id "$NOTARY_KEY_ID" \
    --issuer "$NOTARY_ISSUER" \
    --key "$NOTARY_KEY_PATH" \
    --wait \
    --no-progress \
    --output-format json \
    --verbose \
    2> >(tee "$DIST_DIR/notary-submit-debug.log" >&2)
)"
submit_rc=$?
set -e

printf '%s\n' "$submit_output"

if [[ $submit_rc -ne 0 ]]; then
  die "notarytool submit failed with exit code $submit_rc"
fi

SUBMISSION_ID="$(
  printf '%s' "$submit_output" \
    | python3 -c 'import sys, json; print(json.load(sys.stdin)["id"])'
)"

[[ -n "$SUBMISSION_ID" ]] || die "Could not extract notarization submission id"

xcrun notarytool log "$SUBMISSION_ID" \
  --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER" \
  --key "$NOTARY_KEY_PATH" \
  "$DIST_DIR/notary-log.json"

log_success "Notarization accepted"
log_info "Saved notarization log: $DIST_DIR/notary-log.json"
log_info "Saved submit debug log: $DIST_DIR/notary-submit-debug.log"