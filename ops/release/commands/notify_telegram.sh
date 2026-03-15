#!/usr/bin/env bash
# notify_telegram.sh
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

status="${1:-failure}"

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
  log_warn "Telegram credentials missing. Skipping Telegram notification."
  exit 0
fi

build_id="$(current_build_id)"
branch_name="$(current_branch_name)"
build_url="https://dev.azure.com/clingfy/Clingfy/_build/results?buildId=${build_id}"

# ---------------------------------------------------------
# NEW: Helper to escape HTML for Telegram's strict parser
# ---------------------------------------------------------
escape_html() {
  local text="$1"
  text="${text//&/&amp;}"
  text="${text//</&lt;}"
  text="${text//>/&gt;}"
  printf '%s' "$text"
}

app_name_esc="$(escape_html "$APP_NAME")"
app_version_esc="$(escape_html "$APP_VERSION")"

message=""

if [[ "$status" == "success" ]]; then
  message+=$'🚀 <b>New Release: '
  message+="${app_name_esc}"
  message+=$' v'
  message+="${app_version_esc}"
  message+=$'</b>\n\n'

  if [[ -f "$RELEASE_NOTES_TEMP" ]]; then
    message+=$'📝 <b>What\'s New:</b>\n'
    while IFS= read -r line; do
      line="${line#- }"
      if [[ -n "$line" ]]; then
        message+=$'• '
        # Escape the changelog lines!
        message+="$(escape_html "$line")"
        message+=$'\n'
      fi
    done < "$RELEASE_NOTES_TEMP"
    message+=$'\n'
  fi

  message+=$'📦 <a href="'
  message+="${DOWNLOAD_BASE_URL}${FINAL_DMG_NAME}"
  message+=$'">Download DMG</a>\n'
  message+=$'✅ Release published successfully.'
else
  message+=$'⚠️ <b>Build Failed: '
  message+="${app_name_esc}"
  message+=$'</b>\n'
  message+=$'<b>Branch:</b> '
  message+="$(escape_html "$branch_name")"
  message+=$'\n'
  message+=$'<b>Run ID:</b> '
  message+="${build_id}"
  message+=$'\n\n'
  message+=$'🔗 <a href="'
  message+="${build_url}"
  message+=$'">View Build Logs</a>'
fi

# ---------------------------------------------------------
# NEW: Better curl execution to capture Telegram's error body
# ---------------------------------------------------------
response=$(curl -s -w "\n%{http_code}" -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${message}" \
  --data-urlencode "parse_mode=HTML")

# Extract the HTTP status code (last line) and the body (everything else)
http_code=$(tail -n1 <<< "$response")
body=$(sed '$ d' <<< "$response")

if [[ "$http_code" != "200" ]]; then
  log_error "Telegram API failed with HTTP $http_code"
  log_error "Telegram Response: $body"
  exit 1
fi

log_success "Telegram notification sent (${status})"