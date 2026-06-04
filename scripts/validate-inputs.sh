#!/usr/bin/env bash

set -euo pipefail

# Keep the existing public inputs, but surface which ones are no-ops today.
if [ ! -f "${ACTION_SBOM_PATH}" ]; then
  echo "::error::SBOM file not found at ${ACTION_SBOM_PATH}"
  exit 1
fi

if [ -n "${ACTION_IMAGE}" ]; then
  echo "::warning::Input \"image\" is accepted, but ignored."
fi

if [ "${ACTION_RETRY_ATTEMPTS}" != "3" ] || [ "${ACTION_RETRY_DELAY}" != "5" ]; then
  echo "::warning::Inputs \"retry-attempts\" and \"retry-delay\" are accepted, but currently ignored."
fi
