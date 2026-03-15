#!/usr/bin/env bash
# apple.sh

require_apple_build_env() {
  [[ -n "${APPLE_PROV_PROFILE_SPECIFIER:-}" ]] || die "APPLE_PROV_PROFILE_SPECIFIER is required"
}

require_notary_env() {
  [[ -n "${NOTARY_KEY_ID:-}" ]]   || die "NOTARY_KEY_ID is missing"
  [[ -n "${NOTARY_ISSUER:-}" ]]   || die "NOTARY_ISSUER is missing"
  [[ -n "${NOTARY_KEY_PATH:-}" ]] || die "NOTARY_KEY_PATH is missing"
}

resolve_local_provisioning_profile_path() {
  local base_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
  local candidate=""

  [[ -d "$base_dir" ]] || return 1

  # Prefer exact specifier/name match
  if [[ -n "${APPLE_PROV_PROFILE_SPECIFIER:-}" ]]; then
    for ext in provisionprofile mobileprovision; do
      candidate="$base_dir/${APPLE_PROV_PROFILE_SPECIFIER}.${ext}"
      [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
    done
  fi

  # Fallback to UUID match
  if [[ -n "${APPLE_PROV_PROFILE_UUID:-}" ]]; then
    for ext in provisionprofile mobileprovision; do
      candidate="$base_dir/${APPLE_PROV_PROFILE_UUID}.${ext}"
      [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
    done
  fi

  return 1
}

generate_export_options_plist() {
  [[ -n "${APPLE_PROV_PROFILE_SPECIFIER:-}" ]] || die "APPLE_PROV_PROFILE_SPECIFIER is missing"

  cat > "$EXPORT_OPTIONS_PLIST" <<EOINNER
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>

  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>

  <key>signingStyle</key>
  <string>manual</string>

  <key>signingCertificate</key>
  <string>Developer ID Application</string>

  <key>provisioningProfiles</key>
  <dict>
    <key>$APP_BUNDLE_ID</key>
    <string>$APPLE_PROV_PROFILE_SPECIFIER</string>
  </dict>
</dict>
</plist>
EOINNER
}