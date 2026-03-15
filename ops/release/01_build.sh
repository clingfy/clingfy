#!/usr/bin/env bash
# 01_build.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/build_archive.sh" "$@"
