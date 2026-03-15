#!/usr/bin/env bash
# 00_version_bump.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/version_bump.sh" "$@"
