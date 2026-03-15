#!/usr/bin/env bash
# local_run_all.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/workflows/local_release.sh" "$@"
