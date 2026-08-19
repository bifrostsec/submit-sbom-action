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

# The action step normally skips this script when no source exists; keep this as
# a defensive guard for direct script usage or future workflow wiring changes.
if [ "${#sbom_paths[@]}" -eq 0 ]; then
  echo "::error::No SBOMs were available to upload. The dependency graph export did not produce an SBOM for this workflow run, and no local sbom-path values were provided. Provide at least one SBOM path or run on the repository default branch at the expected commit."
  exit 1
fi

if [ -z "${ACTION_SERVICE_VERSION:-}" ] && [ -z "${ACTION_IMAGE:-}" ]; then
  echo "::error::Either service-version or image must be provided."
  exit 1
fi

args=(
  "--service=${ACTION_SERVICE}"
)
if [ -n "${ACTION_SERVICE_VERSION:-}" ]; then
  args+=("--service-version=${ACTION_SERVICE_VERSION}")
fi
if [ -n "${ACTION_IMAGE:-}" ]; then
  args+=("--image=${ACTION_IMAGE}")
fi
if [ -n "${ACTION_RETRY_ATTEMPTS:-}" ]; then
  args+=("--retry-attempts=${ACTION_RETRY_ATTEMPTS}")
fi
if [ -n "${ACTION_RETRY_DELAY:-}" ]; then
  args+=("--retry-delay=${ACTION_RETRY_DELAY}s")
fi
if [ -n "${ACTION_GIT_REPO_PATH:-}" ]; then
  args+=("--git-repo-path=${ACTION_GIT_REPO_PATH}")
fi

BIFROST_API_KEY="${ACTION_API_TOKEN}" \
BIFROST_SERVER_URL="${ACTION_API_HOST}" \
  "${CLI_PATH}" "${args[@]}" sbom upload "${sbom_paths[@]}"
