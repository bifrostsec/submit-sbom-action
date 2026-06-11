#!/usr/bin/env bash

set -euo pipefail

sbom_paths=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  if [ -n "${line}" ]; then
    sbom_paths+=("${line}")
  fi
done <<< "${ACTION_SBOM_PATH}"

if [ -n "${ACTION_DEPENDENCY_GRAPH_SBOM_PATH}" ]; then
  sbom_paths+=("${ACTION_DEPENDENCY_GRAPH_SBOM_PATH}")
fi

if [ "${#sbom_paths[@]}" -eq 0 ]; then
  echo "::error::No SBOMs were available to upload. The dependency graph export did not produce an SBOM for this workflow run, and no local sbom-path values were provided. Provide at least one SBOM path or run on the repository default branch at the expected commit."
  exit 1
fi

args=(
  "--service=${ACTION_SERVICE}"
  "--service-version=${ACTION_SERVICE_VERSION}"
)
if [ -n "${ACTION_RETRY_ATTEMPTS}" ]; then
  args+=("--retry-attempts=${ACTION_RETRY_ATTEMPTS}")
fi
if [ -n "${ACTION_RETRY_DELAY}" ]; then
  args+=("--retry-delay=${ACTION_RETRY_DELAY}s")
fi
if [ -n "${ACTION_GIT_BRANCH:-}" ]; then
  args+=("--git-branch=${ACTION_GIT_BRANCH}")
fi
if [ -n "${ACTION_GIT_COMMIT_SHA:-}" ]; then
  args+=("--git-commit-sha=${ACTION_GIT_COMMIT_SHA}")
fi

BIFROST_API_KEY="${ACTION_API_TOKEN}" \
BIFROST_SERVER_URL="${ACTION_API_HOST}" \
  "${CLI_PATH}" "${args[@]}" sbom upload "${sbom_paths[@]}"
