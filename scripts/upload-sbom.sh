#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/sbom-paths.sh"

load_sbom_paths

echo "Submitting SBOM to Bifrost API..."
echo "Service: ${ACTION_SERVICE}"
echo "Service version: ${ACTION_SERVICE_VERSION}"
echo "SBOM files: ${#SBOM_PATHS[@]}"

BIFROST_API_KEY="${ACTION_API_TOKEN}" \
  "${CLI_PATH}" \
  "--server-url=${ACTION_API_HOST}" \
  "--service=${ACTION_SERVICE}" \
  "--service-version=${ACTION_SERVICE_VERSION}" \
  sbom upload "${SBOM_PATHS[@]}"
