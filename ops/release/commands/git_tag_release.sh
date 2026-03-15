#!/usr/bin/env bash
# git_tag_release.sh
#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_config.sh"

if [[ "${RELEASE_CHANNEL:-prod}" != "prod" ]]; then
  log_info "Skipping git tag for non-production channel: ${RELEASE_CHANNEL:-unknown}"
  exit 0
fi

log_step "STEP 6: Creating git tag"

ensure_command git

tag_name="v${APP_VERSION}"

if git rev-parse "$tag_name" >/dev/null 2>&1; then
  log_warn "Tag already exists: $tag_name. Skipping."
  exit 0
fi

git config --global user.email "pipeline@clingfy.com"
git config --global user.name "Clingfy Pipeline Bot"

git tag -a "$tag_name" -m "Release $tag_name [skip ci]"
git push origin "$tag_name"

log_success "Tag pushed: $tag_name"