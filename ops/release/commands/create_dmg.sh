#!/usr/bin/env bash
# create_dmg.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

log_step "STEP 2: Creating DMG"

ensure_command create-dmg
ensure_command codesign

if [[ -d "$EXPORTED_APP_PATH" ]]; then
  APP_SOURCE="$EXPORTED_APP_PATH"
elif [[ -d "$ARCHIVED_APP_PATH" ]]; then
  APP_SOURCE="$ARCHIVED_APP_PATH"
else
  die "App bundle not found. Checked:
- $EXPORTED_APP_PATH
- $ARCHIVED_APP_PATH"
fi

signing_identity="${CERT_HASH:-${APPLE_CERTIFICATE_SIGNING_IDENTITY:-}}"
[[ -n "$signing_identity" ]] || die "DMG signing identity is missing (CERT_HASH or APPLE_CERTIFICATE_SIGNING_IDENTITY)"

rm -rf "$DMG_CANVAS" "$DMG_OUTPUT"
safe_mkdir "$DMG_CANVAS"

ditto "$APP_SOURCE" "$DMG_CANVAS/$XCODE_PRODUCT_NAME.app"

create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 128 \
  --icon "$XCODE_PRODUCT_NAME.app" 150 170 \
  --hide-extension "$XCODE_PRODUCT_NAME.app" \
  --app-drop-link 450 170 \
  --format UDZO \
  --no-internet-enable \
  "$DMG_OUTPUT" \
  "$DMG_CANVAS"

hdiutil verify "$DMG_OUTPUT"

codesign --force --sign "$signing_identity" --timestamp "$DMG_OUTPUT"
codesign --verify --verbose "$DMG_OUTPUT"

echo "APP_ENV=$APP_ENV"
echo "APP_NAME=$APP_NAME"
echo "APP_DISPLAY_NAME=$APP_DISPLAY_NAME"
echo "XCODE_PRODUCT_NAME=$XCODE_PRODUCT_NAME"
echo "ARCHIVE_PATH=$ARCHIVE_PATH"
echo "EXPORT_PATH=$EXPORT_PATH"
echo "ARCHIVED_APP_PATH=$ARCHIVED_APP_PATH"
echo "EXPORTED_APP_PATH=$EXPORTED_APP_PATH"

log_success "DMG created: $DMG_OUTPUT"
