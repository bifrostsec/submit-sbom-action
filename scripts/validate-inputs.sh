#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/sbom-paths.sh"

validate_non_negative_integer() {
  local name="$1"
  local value="$2"

  if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
    echo "::error::Input \"${name}\" must be a non-negative integer"
    exit 1
  fi
}

# Keep the existing public inputs, but surface which ones are no-ops today.
load_sbom_paths

if [ "${#SBOM_PATHS[@]}" -eq 0 ] && [ "${ACTION_DEPENDENCY_GRAPH}" != "true" ]; then
  ensure_sbom_sources
fi

for sbom_path in "${SBOM_PATHS[@]}"; do
  if [ ! -f "${sbom_path}" ]; then
    echo "::error::SBOM file not found at ${sbom_path}"
    exit 1
  fi
done

validate_non_negative_integer "retry-attempts" "${ACTION_RETRY_ATTEMPTS}"
validate_non_negative_integer "retry-delay" "${ACTION_RETRY_DELAY}"

if [ -n "${ACTION_IMAGE}" ]; then
  echo "::warning::Input \"image\" is accepted, but ignored."
fi
