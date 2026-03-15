#!/usr/bin/env bash
# ci_release.sh

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$SCRIPT_ROOT/commands/restore_release_history.sh"
"$SCRIPT_ROOT/commands/version_guard.sh"
"$SCRIPT_ROOT/commands/build_archive.sh"
"$SCRIPT_ROOT/commands/create_dmg.sh"
"$SCRIPT_ROOT/commands/notarize_dmg.sh"
"$SCRIPT_ROOT/commands/staple_and_verify.sh"
"$SCRIPT_ROOT/commands/publish_release.sh"
"$SCRIPT_ROOT/commands/git_tag_release.sh"
