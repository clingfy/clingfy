#!/usr/bin/env bash
# sparkle.sh

find_generate_appcast_tool() {
  local candidates=(
    "/usr/local/bin/generate_appcast"
    "/opt/homebrew/bin/generate_appcast"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  candidate="$(find /usr/local/Caskroom /opt/homebrew/Caskroom -name generate_appcast 2>/dev/null | head -n 1 || true)"
  [[ -n "$candidate" ]] && printf '%s' "$candidate"
}

require_sparkle_tool() {
  local sparkle_bin
  sparkle_bin="$(find_generate_appcast_tool || true)"

  [[ -n "$sparkle_bin" ]] || die "generate_appcast not found. Install Sparkle."
  export SPARKLE_BIN="$sparkle_bin"
}

extract_release_notes() {
  local version="$1"
  local changelog_file="$2"
  local output_file="$3"

  : > "$output_file"

  if [[ -f "$changelog_file" ]]; then
    awk -v version="$version" '
      BEGIN { in_section=0 }
      $0 ~ "^## \\[" version "\\]" { in_section=1; next }
      in_section && $0 ~ "^## \\[" { exit }
      in_section { print }
    ' "$changelog_file" > "$output_file" || true
  fi

  if [[ ! -s "$output_file" ]]; then
    printf 'Bug fixes and performance improvements for v%s.\n' "$version" > "$output_file"
  fi
}
