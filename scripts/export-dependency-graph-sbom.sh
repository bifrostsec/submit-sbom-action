#!/usr/bin/env bash

set -euo pipefail

if [ "${ACTION_DEPENDENCY_GRAPH}" != "true" ]; then
  echo "dependency_graph_sbom_path=" >> "${GITHUB_OUTPUT}"
  exit 0
fi

repository="${ACTION_DEPENDENCY_GRAPH_REPOSITORY:-${DEFAULT_GITHUB_REPOSITORY}}"
if [[ "${repository}" != */* ]]; then
  echo "::error::dependency-graph-repository must be in owner/repo format"
  exit 1
fi

safe_repository="${repository//\//-}"
sbom_path="${RUNNER_TEMP}/dependency-graph-${safe_repository}.spdx.json"
github_host="${GITHUB_API_URL#https://}"
github_host="${github_host#http://}"
github_host="${github_host%%/*}"

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::GitHub CLI (gh) is required to export dependency graph SBOMs"
  exit 1
fi

GH_TOKEN="${GITHUB_TOKEN}" \
gh api \
  --hostname "${github_host}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  --jq '.sbom' \
  "/repos/${repository}/dependency-graph/sbom" \
  > "${sbom_path}"

if [ ! -s "${sbom_path}" ] || [ "$(tr -d '[:space:]' < "${sbom_path}")" = "null" ]; then
  echo "::error::Dependency graph SBOM response did not contain an sbom object"
  exit 1
fi

echo "dependency_graph_sbom_path=${sbom_path}" >> "${GITHUB_OUTPUT}"
