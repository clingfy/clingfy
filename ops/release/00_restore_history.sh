#!/usr/bin/env bash
# 00_restore_history.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/restore_release_history.sh" "$@"
