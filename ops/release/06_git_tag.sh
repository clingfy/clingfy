#!/usr/bin/env bash
# 06_git_tag.sh

set -euo pipefail
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands/git_tag_release.sh" "$@"
