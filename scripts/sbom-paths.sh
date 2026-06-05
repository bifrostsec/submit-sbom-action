#!/usr/bin/env bash

# Parse the sbom-path input into a bash array, preserving spaces within each line.
load_sbom_paths() {
  local default_sbom_path="build/sbom.spdx"
  SBOM_PATHS=()

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    if [ -n "${line}" ]; then
      SBOM_PATHS+=("${line}")
    fi
  done <<< "${ACTION_SBOM_PATH}"

  # Preserve the historical default path, but do not force it when dependency-graph
  # export is the only requested source and the default file is absent.
  if [ "${ACTION_DEPENDENCY_GRAPH:-false}" = "true" ] \
    && [ "${#SBOM_PATHS[@]}" -eq 1 ] \
    && [ "${SBOM_PATHS[0]}" = "${default_sbom_path}" ] \
    && [ ! -e "${default_sbom_path}" ]; then
    SBOM_PATHS=()
  fi
}

append_dependency_graph_sbom_path() {
  if [ -n "${ACTION_DEPENDENCY_GRAPH_SBOM_PATH:-}" ]; then
    SBOM_PATHS+=("${ACTION_DEPENDENCY_GRAPH_SBOM_PATH}")
  fi
}

ensure_sbom_sources() {
  if [ "${#SBOM_PATHS[@]}" -eq 0 ]; then
    echo "::error::At least one SBOM file path is required"
    return 1
  fi
}
