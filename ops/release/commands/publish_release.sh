#!/usr/bin/env bash
# publish_release.sh

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

log_step "STEP 5: Publishing release"

require_azure_cli
require_sparkle_tool
ensure_command curl
ensure_command zip

[[ -f "$DMG_OUTPUT" ]] || die "DMG not found: $DMG_OUTPUT"
[[ -n "${SPARKLE_KEY_PATH:-}" ]] || die "SPARKLE_KEY_PATH is missing"

safe_mkdir "$RELEASE_ARCHIVE"

extract_release_notes "$APP_VERSION" "$CHANGELOG_FILE" "$RELEASE_NOTES_TEMP"

release_dmg_path="$RELEASE_ARCHIVE/$FINAL_DMG_NAME"
cp "$DMG_OUTPUT" "$release_dmg_path"

# Tell Sparkle this is HTML, not plain text!
notes_filename="${FINAL_DMG_NAME%.*}.html"
notes_html_path="$RELEASE_ARCHIVE/$notes_filename"

# 8957e5 # 9467e7 # a078ea # ac89ec # b89aef
# c4abf2 # cfbbf4 # dbccf7 # e7ddf9 # f3eefc
# ffffff

# 1. Inject the HTML Head and CSS Styling
cat << 'EOF' > "$notes_html_path"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <style>
        /* CSS Variables for easy theme management */
        :root {
            --bg-color: #ffffff;
            --text-color: #333333;
            --accent-color: #8957e5;
            --border-color: #eeeeee;
        }
        
        /* Native macOS Dark Mode Support! */
        @media (prefers-color-scheme: dark) {
            :root {
                --bg-color: #1e1e1e;
                --text-color: #e0e0e0;
                --accent-color: #9467e7;
                --border-color: #444444;
            }
        }
        
        body {
            /* Uses the native macOS system font (San Francisco) */
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            font-size: 13px; /* Standard Mac readable size */
            line-height: 1.5;
            padding: 12px 16px;
            margin: 0;
        }
        
        h3 {
            color: var(--accent-color);
            font-size: 15px;
            font-weight: 600;
            margin-top: 0;
            margin-bottom: 8px;
            padding-bottom: 4px;
            border-bottom: 1px solid var(--border-color);
        }
        
        ul {
            margin: 0 0 16px 0;
            padding-left: 20px;
        }
        
        li {
            margin-bottom: 6px;
        }
    </style>
</head>
<body>
EOF

# 2. Append the raw HTML notes extracted from the CHANGELOG
cat "$RELEASE_NOTES_TEMP" >> "$notes_html_path"

# 3. Close the HTML document
cat << 'EOF' >> "$notes_html_path"
</body>
</html>
EOF


log_info "Generating appcast with: $SPARKLE_BIN"
"$SPARKLE_BIN" "$RELEASE_ARCHIVE" \
  -o "$APPCAST_XML" \
  --download-url-prefix "$DOWNLOAD_BASE_URL" \
  --embed-release-notes \
  --ed-key-file "$SPARKLE_KEY_PATH"

log_info "Uploading DMG"
az_upload_blob "$AZ_STORAGE_ACCOUNT" "$AZ_CONTAINER" "$release_dmg_path" "${AZ_BINARIES_FOLDER}/$FINAL_DMG_NAME"

log_info "Uploading appcast.xml"
# az_upload_blob "$AZ_STORAGE_ACCOUNT" "$AZ_CONTAINER" "$APPCAST_XML" "appcast.xml"
az_upload_blob "$AZ_STORAGE_ACCOUNT" "$AZ_CONTAINER" "$APPCAST_XML" "$APPCAST_BLOB_PATH"

log_info "Uploading deltas"
while IFS= read -r -d '' delta_path; do
  delta_name="$(basename "$delta_path")"
  az_upload_blob "$AZ_STORAGE_ACCOUNT" "$AZ_CONTAINER" "$delta_path" "${AZ_BINARIES_FOLDER}/$delta_name"
done < <(find "$RELEASE_ARCHIVE" -type f -name "*.delta" -print0)

log_info "Uploading dSYMs to Azure"
if [[ -d "$ARCHIVE_PATH/dSYMs" ]]; then
  if (
    cd "$ARCHIVE_PATH/dSYMs"
    shopt -s nullglob
    files=( *.dSYM )
    ((${#files[@]} > 0)) || exit 2
    zip -qry "$RELEASE_ARCHIVE/$DSYM_ZIP" "${files[@]}"
  ); then
    # az_upload_blob "$AZ_STORAGE_ACCOUNT" "$AZ_CONTAINER_SYMBOLS" "$RELEASE_ARCHIVE/$DSYM_ZIP" "$DSYM_ZIP"
    az_upload_blob \
      "$AZ_STORAGE_ACCOUNT" \
      "$AZ_CONTAINER_SYMBOLS" \
      "$RELEASE_ARCHIVE/$DSYM_ZIP" \
      "${AZ_SYMBOLS_BLOB_PREFIX}${DSYM_ZIP}"
    log_success "dSYMs uploaded to Azure"
  else
    log_warn "No .dSYM bundles found. Skipping Azure symbols upload."
  fi
else
  log_warn "dSYMs folder not found: $ARCHIVE_PATH/dSYMs"
fi

log_info "Uploading symbols to Sentry (non-blocking)"
if [[ -n "${SENTRY_AUTH_TOKEN:-}" && -n "${SENTRY_ORG:-}" && -n "${SENTRY_PROJECT:-}" ]]; then
  rm -rf "$PROJECT_ROOT/build/symbols"
  safe_mkdir "$PROJECT_ROOT/build/symbols"

  if [[ -d "$ARCHIVE_PATH/dSYMs" ]]; then
    cp -R "$ARCHIVE_PATH/dSYMs/"* "$PROJECT_ROOT/build/symbols/" 2>/dev/null || true
  fi

  if compgen -G "$PROJECT_ROOT/build/symbols/*.dSYM" >/dev/null; then
    if ! (
      cd "$PROJECT_ROOT"
      dart run sentry_dart_plugin
    ); then
      log_warn "Sentry symbol upload failed. Continuing release."
    fi
  else
    log_warn "No staged .dSYM bundles for Sentry. Skipping."
  fi
else
  log_warn "Sentry env vars missing. Skipping Sentry upload."
fi

log_info "Purging Azure Front Door cache"
purge_frontdoor_paths \
  "$AZ_RESOURCE_GROUP" \
  "$AZ_CDN_PROFILE" \
  "$AZ_FRONTDOOR_ENDPOINT_NAME" \
  "$AZ_CDN_ENDPOINT" \
  "/${FEED_PATH}" \
  "/${AZ_BINARIES_FOLDER}/${FINAL_DMG_NAME}"

log_info "Smoke testing published assets"

appcast_ok="false"
for _attempt in {1..9}; do
  if curl -fsS "$FEED_URL" | grep -q "$FINAL_DMG_NAME"; then
    appcast_ok="true"
    break
  fi
  sleep 5
done

[[ "$appcast_ok" == "true" ]] || die "Smoke test failed: appcast.xml does not reference $FINAL_DMG_NAME"

dmg_url="${DOWNLOAD_BASE_URL}${FINAL_DMG_NAME}"
dmg_status="$(curl -sSIL -o /dev/null -w "%{http_code}" "$dmg_url" || true)"
[[ "$dmg_status" == "200" ]] || die "Smoke test failed: DMG returned HTTP $dmg_status"

log_success "Release published successfully"
log_info "Download URL: $dmg_url"
