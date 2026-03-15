#!/usr/bin/env bash
# 03_notarize.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/notarize_dmg.sh" "$@"
