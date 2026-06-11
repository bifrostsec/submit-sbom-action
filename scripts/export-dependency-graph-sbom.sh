#!/usr/bin/env bash

set -euo pipefail

skip_dependency_graph() {
  if [ -n "${1:-}" ]; then
    echo "::warning::$1"
  fi

  echo "dependency_graph_sbom_path=" >> "${GITHUB_OUTPUT}"
  exit 0
}

if [ "${ACTION_DEPENDENCY_GRAPH}" != "true" ]; then
  skip_dependency_graph
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::GitHub CLI (gh) is required to export dependency graph SBOMs"
  exit 1
fi

github_host="${GITHUB_SERVER_URL#https://}"
github_host="${github_host#http://}"
github_host="${github_host%%/*}"
sbom_path="${RUNNER_TEMP}/dependency-graph-${GITHUB_REPOSITORY//\//-}.spdx.json"

gh_api() {
  gh api \
    --hostname "${github_host}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2026-03-10" \
    "$@"
}

# Only use dependency graph data from the current repository default branch.
default_branch="$(gh_api "/repos/${GITHUB_REPOSITORY}" --jq '.default_branch')"
if [ "${GITHUB_REF_NAME}" != "${default_branch}" ]; then
  skip_dependency_graph "Dependency graph export only uses the default branch (${default_branch}); current ref is ${GITHUB_REF_NAME}."
fi

current_head_sha="$(gh_api "/repos/${GITHUB_REPOSITORY}/branches/${default_branch}" --jq '.commit.sha')"
if [ "${current_head_sha}" != "${GITHUB_SHA}" ]; then
  skip_dependency_graph "Dependency graph export skipped because ${GITHUB_REPOSITORY}@${default_branch} is at ${current_head_sha}, not ${GITHUB_SHA}."
fi

# The endpoint wraps the SPDX document in {"sbom": ...}; unwrap it before upload.
gh_api "/repos/${GITHUB_REPOSITORY}/dependency-graph/sbom" --jq '.sbom' > "${sbom_path}"

if [ ! -s "${sbom_path}" ] || [ "$(tr -d '[:space:]' < "${sbom_path}")" = "null" ]; then
  echo "::error::Dependency graph SBOM response did not contain an SBOM document"
  exit 1
fi

echo "dependency_graph_sbom_path=${sbom_path}" >> "${GITHUB_OUTPUT}"
