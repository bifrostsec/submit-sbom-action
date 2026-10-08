#!/usr/bin/env bash

set -euo pipefail

skip_dependency_graph() {
  echo "::warning::$1"
  echo "dependency_graph_sbom_path=" >> "${GITHUB_OUTPUT}"
  exit 0
}

# Check that curl and jq is available on the vm
for tool in curl jq; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "::error::${tool} is required to export dependency graph SBOMs"
    exit 1
  fi
done

sbom_path="${RUNNER_TEMP}/dependency-graph-${GITHUB_REPOSITORY//\//-}.spdx.json"
response_path="$(mktemp "${RUNNER_TEMP}/dependency-graph-response.XXXXXX")"
trap 'rm -f "${response_path}"' EXIT

github_api() {
  local endpoint="$1"
  local json_filter="$2"

  curl --fail --location --show-error --silent \
    --retry 5 \
    --retry-connrefused \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2026-03-10" \
    --output "${response_path}" \
    "${GITHUB_API_URL%/}${endpoint}" || return $?

  jq -er "${json_filter}" "${response_path}"
}

# Only use dependency graph data from the current repository default branch.
default_branch="$(github_api "/repos/${GITHUB_REPOSITORY}" '.default_branch')"
if [ "${GITHUB_REF_NAME}" != "${default_branch}" ]; then
  skip_dependency_graph "Dependency graph export only uses the default branch (${default_branch}); current ref is ${GITHUB_REF_NAME}."
fi

# Check that the workflow commit is still the branch head.
default_branch_encoded="$(jq -rn --arg branch "${default_branch}" '$branch | @uri')"
current_head_sha="$(github_api "/repos/${GITHUB_REPOSITORY}/branches/${default_branch_encoded}" '.commit.sha')"
if [ "${current_head_sha}" != "${GITHUB_SHA}" ]; then
  skip_dependency_graph "Dependency graph export skipped because ${GITHUB_REPOSITORY}@${default_branch} is at ${current_head_sha}, not ${GITHUB_SHA}."
fi

# Export and validate the SBOM.
if ! github_api "/repos/${GITHUB_REPOSITORY}/dependency-graph/sbom" '.sbom' > "${sbom_path}"; then
  echo "::error::Failed to export dependency graph SBOM: request failed or response did not contain an SBOM document"
  exit 1
fi

# Publish the SBOM path.
echo "dependency_graph_sbom_path=${sbom_path}" >> "${GITHUB_OUTPUT}"
