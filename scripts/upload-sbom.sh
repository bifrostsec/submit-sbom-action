#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/sbom-paths.sh"

load_sbom_paths
append_dependency_graph_sbom_path
ensure_sbom_sources

echo "Submitting SBOM to Bifrost API..."
echo "Service: ${ACTION_SERVICE}"
echo "Service version: ${ACTION_SERVICE_VERSION}"
echo "SBOM files: ${#SBOM_PATHS[@]}"
echo "Retry attempts: ${ACTION_RETRY_ATTEMPTS}"
echo "Retry delay: ${ACTION_RETRY_DELAY}s"

BIFROST_API_KEY="${ACTION_API_TOKEN}" \
  "${CLI_PATH}" \
  "--server-url=${ACTION_API_HOST}" \
  "--service=${ACTION_SERVICE}" \
  "--service-version=${ACTION_SERVICE_VERSION}" \
  "--retry-attempts=${ACTION_RETRY_ATTEMPTS}" \
  "--retry-delay=${ACTION_RETRY_DELAY}s" \
  sbom upload "${SBOM_PATHS[@]}"
