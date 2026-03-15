#!/usr/bin/env bash
# context.sh

is_ci() {
  [[ -n "${TF_BUILD:-}" || -n "${BUILD_BUILDID:-}" || -n "${CI:-}" ]]
}

current_build_id() {
  printf '%s' "${BUILD_BUILDID:-$(date +%s)}"
}

# current_branch_name() {
#   local branch="${BUILD_SOURCEBRANCHNAME:-${BUILD_SOURCEBRANCH:-local}}"
#   branch="${branch#refs/heads/}"
#   printf '%s' "$branch"
# }

current_branch_name() {
  local branch=""

  if [[ -n "${BUILD_SOURCEBRANCH:-}" ]]; then
    branch="${BUILD_SOURCEBRANCH#refs/heads/}"
  elif [[ -n "${BUILD_SOURCEBRANCHNAME:-}" ]]; then
    branch="${BUILD_SOURCEBRANCHNAME}"
  else
    branch="local"
  fi

  printf '%s' "$branch"
}

is_release_branch() {
  [[ "$(current_branch_name)" == release/* ]]
}

is_main_branch() {
  [[ "$(current_branch_name)" == "main" ]]
}

release_version_from_branch() {
  local branch
  branch="$(current_branch_name)"
  if [[ "$branch" == release/* ]]; then
    printf '%s' "${branch#release/}"
  fi
}
