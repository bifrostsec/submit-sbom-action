#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/sbom-paths.sh"

# Keep the existing public inputs, but surface which ones are no-ops today.
load_sbom_paths

for sbom_path in "${SBOM_PATHS[@]}"; do
  if [ ! -f "${sbom_path}" ]; then
    echo "::error::SBOM file not found at ${sbom_path}"
    exit 1
  fi
done

if [ -n "${ACTION_IMAGE}" ]; then
  echo "::warning::Input \"image\" is accepted, but ignored."
fi

if [ "${ACTION_RETRY_ATTEMPTS}" != "3" ] || [ "${ACTION_RETRY_DELAY}" != "5" ]; then
  echo "::warning::Inputs \"retry-attempts\" and \"retry-delay\" are accepted, but currently ignored."
fi
