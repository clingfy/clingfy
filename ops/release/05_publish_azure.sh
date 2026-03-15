#!/usr/bin/env bash
# 05_publish_azure.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/publish_release.sh" "$@"
