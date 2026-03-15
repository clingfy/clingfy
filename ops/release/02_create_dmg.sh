#!/usr/bin/env bash
# 02_create_dmg.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/create_dmg.sh" "$@"
