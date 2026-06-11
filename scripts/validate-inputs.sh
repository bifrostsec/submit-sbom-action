#!/usr/bin/env bash

set -euo pipefail

validate_non_negative_integer() {
  local name="$1"
  local value="$2"

  if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
    echo "::error::Input \"${name}\" must be a non-negative integer"
    exit 1
  fi
}

sbom_paths=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  if [ -n "${line}" ]; then
    sbom_paths+=("${line}")
  fi
done <<< "${ACTION_SBOM_PATH}"

# The guard keeps the empty-array expansion safe under set -u on bash < 4.4.
if [ "${#sbom_paths[@]}" -gt 0 ]; then
  for sbom_path in "${sbom_paths[@]}"; do
    if [ ! -f "${sbom_path}" ]; then
      echo "::error::SBOM file not found at ${sbom_path}"
      exit 1
    fi
  done
fi

validate_non_negative_integer "retry-attempts" "${ACTION_RETRY_ATTEMPTS}"
validate_non_negative_integer "retry-delay" "${ACTION_RETRY_DELAY}"

if [ -n "${ACTION_IMAGE}" ]; then
  echo "::warning::Input \"image\" is accepted, but ignored."
fi

if [ "${#sbom_paths[@]}" -eq 0 ] && [ "${ACTION_DEPENDENCY_GRAPH}" != "true" ]; then
  echo "::warning::No SBOM source configured; no SBOM will be submitted."
  echo "upload_required=false" >> "${GITHUB_OUTPUT}"
  exit 0
fi

echo "upload_required=true" >> "${GITHUB_OUTPUT}"
