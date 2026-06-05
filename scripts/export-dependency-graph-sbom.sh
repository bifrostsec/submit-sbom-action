#!/usr/bin/env bash

set -euo pipefail

if [ "${ACTION_DEPENDENCY_GRAPH}" != "true" ]; then
  echo "dependency_graph_sbom_path=" >> "${GITHUB_OUTPUT}"
  exit 0
fi

repository="${ACTION_DEPENDENCY_GRAPH_REPOSITORY:-${DEFAULT_GITHUB_REPOSITORY}}"
if [[ "${repository}" != */* ]]; then
  echo "::error::dependency-graph-repository must be in owner/repo format"
  exit 1
fi

python_cmd=""
if command -v python3 >/dev/null 2>&1; then
  python_cmd="python3"
elif command -v python >/dev/null 2>&1; then
  python_cmd="python"
else
  echo "::error::Python is required to normalize the dependency graph SBOM response"
  exit 1
fi

safe_repository="${repository//\//-}"
raw_path="${RUNNER_TEMP}/dependency-graph-${safe_repository}.raw.json"
sbom_path="${RUNNER_TEMP}/dependency-graph-${safe_repository}.spdx.json"

curl --fail --silent --show-error --location \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "${GITHUB_API_URL}/repos/${repository}/dependency-graph/sbom" \
  --output "${raw_path}"

"${python_cmd}" - "${raw_path}" "${sbom_path}" <<'PY'
import json
import sys

raw_path, sbom_path = sys.argv[1], sys.argv[2]
with open(raw_path, encoding="utf-8") as f:
    payload = json.load(f)

sbom = payload.get("sbom")
if not isinstance(sbom, dict):
    raise SystemExit("Dependency graph SBOM response did not contain an sbom object")

with open(sbom_path, "w", encoding="utf-8") as f:
    json.dump(sbom, f, separators=(",", ":"))
PY

echo "dependency_graph_sbom_path=${sbom_path}" >> "${GITHUB_OUTPUT}"
