#!/usr/bin/env bash

# Parse the sbom-path input into a bash array, preserving spaces within each line.
load_sbom_paths() {
  SBOM_PATHS=()

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    if [ -n "${line}" ]; then
      SBOM_PATHS+=("${line}")
    fi
  done <<< "${ACTION_SBOM_PATH}"

  if [ "${#SBOM_PATHS[@]}" -eq 0 ]; then
    echo "::error::At least one SBOM file path is required"
    return 1
  fi
}
