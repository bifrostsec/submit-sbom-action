#!/usr/bin/env bash

set -euo pipefail

sbom_paths=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  if [ -n "${line}" ]; then
    sbom_paths+=("${line}")
  fi
done <<< "${ACTION_SBOM_PATH}"

# Default to build/sbom.spdx unless dependency-graph export is the only SBOM source.
if [ "${#sbom_paths[@]}" -eq 0 ] && [ "${ACTION_DEPENDENCY_GRAPH}" != "true" ]; then
  sbom_paths=("build/sbom.spdx")
fi

if [ -n "${ACTION_DEPENDENCY_GRAPH_SBOM_PATH}" ]; then
  sbom_paths+=("${ACTION_DEPENDENCY_GRAPH_SBOM_PATH}")
fi

if [ "${#sbom_paths[@]}" -eq 0 ]; then
  if [ "${ACTION_DEPENDENCY_GRAPH}" = "true" ]; then
    echo "::error::No SBOMs were available to upload. The dependency graph export did not produce an SBOM for this workflow run, and no local sbom-path values were provided. Provide at least one SBOM path or run on the repository default branch at the expected commit."
    exit 1
  fi

  echo "::error::At least one SBOM file path is required"
  exit 1
fi

echo "Submitting SBOM to Bifrost API..."
echo "Service: ${ACTION_SERVICE}"
echo "Service version: ${ACTION_SERVICE_VERSION}"
echo "SBOM files: ${#sbom_paths[@]}"
echo "Retry attempts: ${ACTION_RETRY_ATTEMPTS}"
echo "Retry delay: ${ACTION_RETRY_DELAY}s"

BIFROST_API_KEY="${ACTION_API_TOKEN}" \
  "${CLI_PATH}" \
  "--server-url=${ACTION_API_HOST}" \
  "--service=${ACTION_SERVICE}" \
  "--service-version=${ACTION_SERVICE_VERSION}" \
  "--retry-attempts=${ACTION_RETRY_ATTEMPTS}" \
  "--retry-delay=${ACTION_RETRY_DELAY}s" \
  sbom upload "${sbom_paths[@]}"
