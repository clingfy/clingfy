#!/usr/bin/env bash
# local_release.sh

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🚀 STARTING LOCAL RELEASE PIPELINE"

if [[ "${RUN_RESTORE_HISTORY:-false}" == "true" ]]; then
  "$SCRIPT_ROOT/commands/restore_release_history.sh"
fi

"$SCRIPT_ROOT/commands/build_archive.sh"
"$SCRIPT_ROOT/commands/create_dmg.sh"
"$SCRIPT_ROOT/commands/notarize_dmg.sh"
"$SCRIPT_ROOT/commands/staple_and_verify.sh"

if [[ "${RUN_PUBLISH:-false}" == "true" ]]; then
  "$SCRIPT_ROOT/commands/publish_release.sh"
fi

echo "✅ LOCAL RELEASE PIPELINE FINISHED"

# sudo find ops/release -type f -name "*.sh" -exec chmod +x {} +
