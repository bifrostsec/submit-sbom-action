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
github_api_url="${GITHUB_API_URL%/}"
sbom_path="${RUNNER_TEMP}/dependency-graph-${GITHUB_REPOSITORY//\//-}.spdx.json"

gh_api() {
  gh api \
    --hostname "${github_host}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2026-03-10" \
    "$@"
}

branch_head_sha() {
  gh_api "/repos/${GITHUB_REPOSITORY}/branches/${default_branch}" --jq '.commit.sha'
}

# Only use dependency graph data from the current repository default branch.
default_branch="$(gh_api "/repos/${GITHUB_REPOSITORY}" --jq '.default_branch')"
if [ "${GITHUB_REF_NAME}" != "${default_branch}" ]; then
  skip_dependency_graph "Dependency graph export only uses the default branch (${default_branch}); current ref is ${GITHUB_REF_NAME}."
fi

current_head_sha="$(branch_head_sha)"
if [ "${current_head_sha}" != "${GITHUB_SHA}" ]; then
  skip_dependency_graph "Dependency graph export skipped because ${GITHUB_REPOSITORY}@${default_branch} is at ${current_head_sha}, not ${GITHUB_SHA}."
fi

attempts=12
delay_seconds=5

# Ask GitHub to build a report once, then poll the report endpoint until it is ready.
report_url="$(gh_api "/repos/${GITHUB_REPOSITORY}/dependency-graph/sbom/generate-report" --jq '.sbom_url')"
if [ -z "${report_url}" ] || [ "${report_url}" = "null" ]; then
  echo "::error::Dependency graph report request did not return an sbom_url"
  exit 1
fi

report_endpoint="${report_url#"${github_api_url}"}"
if [ "${report_endpoint}" = "${report_url}" ]; then
  echo "::error::Dependency graph report URL ${report_url} does not match ${github_api_url}"
  exit 1
fi

for attempt in $(seq 1 "${attempts}"); do
  # Abort if the branch moves while waiting; the report may no longer match this run.
  current_head_sha="$(branch_head_sha)"
  if [ "${current_head_sha}" != "${GITHUB_SHA}" ]; then
    skip_dependency_graph "Dependency graph export skipped because ${GITHUB_REPOSITORY}@${default_branch} moved to ${current_head_sha} while waiting for ${GITHUB_SHA}."
  fi

  response_headers="$(gh_api --include --silent "${report_endpoint}")"
  status_code="$(printf '%s\n' "${response_headers}" | awk 'NR==1 {print $2}')"

  case "${status_code}" in
    200)
      gh_api "${report_endpoint}" > "${sbom_path}"

      if [ ! -s "${sbom_path}" ] || [ "$(tr -d '[:space:]' < "${sbom_path}")" = "null" ]; then
        echo "::error::Dependency graph SBOM response did not contain an SBOM document"
        exit 1
      fi

      echo "dependency_graph_sbom_path=${sbom_path}" >> "${GITHUB_OUTPUT}"
      exit 0
      ;;
    202)
      ;;
    *)
      echo "::error::Dependency graph report fetch returned HTTP ${status_code}"
      exit 1
      ;;
  esac

  if [ "${attempt}" -lt "${attempts}" ]; then
    sleep "${delay_seconds}"
  fi
done

skip_dependency_graph "Dependency graph SBOM report was not ready for ${GITHUB_REPOSITORY}@${GITHUB_SHA} before timeout."
