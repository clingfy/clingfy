#!/usr/bin/env bash
# 04_finish.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/staple_and_verify.sh" "$@"
