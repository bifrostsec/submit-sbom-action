#!/usr/bin/env bash

set -euo pipefail

echo "Submitting SBOM to Bifrost API..."
echo "Service: ${ACTION_SERVICE}"
echo "Service version: ${ACTION_SERVICE_VERSION}"

BIFROST_API_KEY="${ACTION_API_TOKEN}" \
  "${CLI_PATH}" \
  "--server-url=${ACTION_API_HOST}" \
  "--service=${ACTION_SERVICE}" \
  "--service-version=${ACTION_SERVICE_VERSION}" \
  sbom upload "${ACTION_SBOM_PATH}"
