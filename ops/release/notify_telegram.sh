#!/usr/bin/env bash
# notify_telegram.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/notify_telegram.sh" "$@"
