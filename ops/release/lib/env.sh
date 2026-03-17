#!/usr/bin/env bash
# env.sh

load_env_file() {
  local env_file="$PROJECT_ROOT/.env.$APP_ENV"
  local temp_env

  [[ -f "$env_file" ]] || die "Environment file not found: $env_file"

  log_info "Loading environment file: .env.$APP_ENV"

  temp_env="$(mktemp)"
  tr -d '\r' < "$env_file" > "$temp_env"

  set -a
  # shellcheck disable=SC1090
  source "$temp_env"
  set +a

  rm -f "$temp_env"
}

read_pubspec_version_info() {
  local version_line
  version_line="$(grep '^version:' "$PROJECT_ROOT/pubspec.yaml" | awk '{print $2}')"

  [[ -n "$version_line" ]] || die "Could not read version from pubspec.yaml"

  local pubspec_app_version="${version_line%%+*}"
  local pubspec_build_number="1"

  if [[ "$version_line" == *"+"* ]]; then
    pubspec_build_number="${version_line#*+}"
  fi

  export APP_VERSION="${APP_VERSION_OVERRIDE:-$pubspec_app_version}"
  export BUILD_NUMBER="${BUILD_NUMBER_OVERRIDE:-$pubspec_build_number}"
  export APP_VERSION_FULL="${APP_VERSION}+${BUILD_NUMBER}"
}

configure_app_flavor() {
  export BASE_APP_NAME="Clingfy"
  export BASE_BUNDLE_ID="com.clingfy.clingfy"
  export APPLE_TEAM_ID="${APPLE_TEAM_ID:-46LWU2HLR5}"

  case "$APP_ENV" in
    prod)
      export APP_DISPLAY_NAME="$BASE_APP_NAME"
      export APP_BUNDLE_ID="$BASE_BUNDLE_ID"
      ;;
    dev)
      export APP_DISPLAY_NAME="${BASE_APP_NAME} Dev"
      export APP_BUNDLE_ID="${BASE_BUNDLE_ID}.dev"
      ;;
    *)
      export APP_DISPLAY_NAME="${BASE_APP_NAME} Local"
      export APP_BUNDLE_ID="${BASE_BUNDLE_ID}.local"
      ;;
  esac

  export APP_NAME="$APP_DISPLAY_NAME"
}

configure_paths() {
  export ARCHIVE_PATH="$PROJECT_ROOT/build/macos/Runner.xcarchive"
  export EXPORT_PATH="$PROJECT_ROOT/build/macos/Build/Products/Release"

  export XCODE_PRODUCT_NAME="${XCODE_PRODUCT_NAME:-Clingfy}"

  export ARCHIVED_APP_PATH="$ARCHIVE_PATH/Products/Applications/$XCODE_PRODUCT_NAME.app"
  export EXPORTED_APP_PATH="$EXPORT_PATH/$XCODE_PRODUCT_NAME.app"

  export DIST_DIR="$PROJECT_ROOT/dist"
  export DMG_CANVAS="$DIST_DIR/dmg_canvas"
  export DMG_OUTPUT="$DIST_DIR/${APP_DISPLAY_NAME// /_}.dmg"

  export RELEASE_ARCHIVE="$PROJECT_ROOT/release_archive"
  export EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$SCRIPT_ROOT/ExportOptionsManual.plist}"

  export APPCAST_XML="$RELEASE_ARCHIVE/appcast.xml"
  export RELEASE_NOTES_TEMP="$RELEASE_ARCHIVE/release_notes.txt"
  export CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"

  # export FINAL_DMG_NAME="${APP_DISPLAY_NAME// /_}_${APP_VERSION}.dmg"
  # export DSYM_ZIP="${APP_DISPLAY_NAME// /_}_${APP_VERSION}_dSYM.zip"

  # prod: Clingfy_1.0.0.dmg
  # dev : Clingfy_Dev_1.0.0+1523.dmg  (unique per run)
  case "${RELEASE_CHANNEL:-$APP_ENV}" in
    prod)
      export FINAL_DMG_NAME="${APP_DISPLAY_NAME// /_}_${APP_VERSION}.dmg"
      export DSYM_ZIP="${APP_DISPLAY_NAME// /_}_${APP_VERSION}_dSYM.zip"
      ;;
    dev)
      export FINAL_DMG_NAME="${APP_DISPLAY_NAME// /_}_${APP_VERSION}+${BUILD_NUMBER}.dmg"
      export DSYM_ZIP="${APP_DISPLAY_NAME// /_}_${APP_VERSION}+${BUILD_NUMBER}_dSYM.zip"
      ;;
    *)
      export FINAL_DMG_NAME="${APP_DISPLAY_NAME// /_}_${APP_VERSION}+${BUILD_NUMBER}.dmg"
      export DSYM_ZIP="${APP_DISPLAY_NAME// /_}_${APP_VERSION}+${BUILD_NUMBER}_dSYM.zip"
      ;;
  esac
}

configure_azure_defaults() {
  export AZ_CONTAINER_SYMBOLS="${AZ_CONTAINER_SYMBOLS:-symbols}"
  case "${RELEASE_CHANNEL:-$APP_ENV}" in
    prod)
      export AZ_CONTAINER="${AZ_CONTAINER:-updates}"
      export AZ_BINARIES_FOLDER="${AZ_BINARIES_FOLDER:-downloads}"
      export AZ_SYMBOLS_BLOB_PREFIX=""
      export APPCAST_BLOB_PATH="appcast.xml"
      export FEED_PATH="appcast.xml"
      ;;
    dev)
      export AZ_CONTAINER="${AZ_CONTAINER:-updates}"
      export AZ_BINARIES_FOLDER="${AZ_BINARIES_FOLDER:-downloads}"
      export AZ_SYMBOLS_BLOB_PREFIX=""
      export APPCAST_BLOB_PATH="appcast.xml"
      export FEED_PATH="appcast.xml"
      ;;
    *)
      export AZ_CONTAINER="${AZ_CONTAINER:-updates}"
      export AZ_BINARIES_FOLDER="${AZ_BINARIES_FOLDER:-local/downloads}"
      export AZ_SYMBOLS_BLOB_PREFIX="local/"
      export APPCAST_BLOB_PATH="local/appcast.xml"
      export FEED_PATH="local/appcast.xml"
      ;;
  esac

  export DOWNLOAD_BASE_URL="https://${AZ_CDN_ENDPOINT}/${AZ_BINARIES_FOLDER}/"
  export FEED_URL="https://${AZ_CDN_ENDPOINT}/${FEED_PATH}"
}



load_release_context() {
  export APP_ENV="${1:-local}"
  export SCRIPT_ROOT="${2:?script root is required}"
  export PROJECT_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"
  export RELEASE_CHANNEL="${RELEASE_CHANNEL:-$APP_ENV}"

  load_env_file
  configure_app_flavor
  read_pubspec_version_info
  configure_paths
  configure_azure_defaults
}
