#!/usr/bin/env bash

set -euo pipefail

sbom_paths=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  if [ -n "${line}" ]; then
    sbom_paths+=("${line}")
  fi
done <<< "${ACTION_SBOM_PATH}"

if [ -n "${ACTION_DEPENDENCY_GRAPH_SBOM_PATH}" ]; then
  sbom_paths+=("${ACTION_DEPENDENCY_GRAPH_SBOM_PATH}")
fi

# The action step normally skips this script when no source exists; keep this as
# a defensive guard for direct script usage or future workflow wiring changes.
if [ "${#sbom_paths[@]}" -eq 0 ]; then
  echo "::error::No SBOMs were available to upload. The dependency graph export did not produce an SBOM for this workflow run, and no local sbom-path values were provided. Provide at least one SBOM path or run on the repository default branch at the expected commit."
  exit 1
fi

if [ -z "${ACTION_SERVICE_VERSION:-}" ] && [ -z "${ACTION_IMAGE:-}" ]; then
  echo "::error::Either service-version or image must be provided."
  exit 1
fi

# Authenticate with either a bifrost API token or the GitHub OIDC token of the
# job, which the CLI exchanges for a short-lived access token when given an
# organization id.
if [ -n "${ACTION_API_TOKEN:-}" ] && [ -n "${ACTION_ORG_ID:-}" ]; then
  echo "::error::Provide either api-token or org-id, not both. Use api-token to authenticate with a bifrost API token, or org-id to authenticate with the GitHub OIDC token of the job."
  exit 1
fi
if [ -z "${ACTION_API_TOKEN:-}" ] && [ -z "${ACTION_ORG_ID:-}" ]; then
  echo "::error::Either api-token or org-id must be provided. Use api-token to authenticate with a bifrost API token, or org-id to authenticate with the GitHub OIDC token of the job."
  exit 1
fi
if [ -n "${ACTION_ORG_ID:-}" ] && { [ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ] || [ -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]; }; then
  echo '::error::GitHub OIDC authentication with org-id requires the job to grant `permissions: id-token: write`. GitHub does not make an OIDC token available to workflows triggered by pull requests from forked repositories.'
  exit 1
fi

args=(
  "--service=${ACTION_SERVICE}"
)
if [ -n "${ACTION_SERVICE_VERSION:-}" ]; then
  args+=("--service-version=${ACTION_SERVICE_VERSION}")
fi
if [ -n "${ACTION_IMAGE:-}" ]; then
  args+=("--image=${ACTION_IMAGE}")
fi
if [ -n "${ACTION_RETRY_ATTEMPTS:-}" ]; then
  args+=("--retry-attempts=${ACTION_RETRY_ATTEMPTS}")
fi
if [ -n "${ACTION_RETRY_DELAY:-}" ]; then
  args+=("--retry-delay=${ACTION_RETRY_DELAY}s")
fi
if [ -n "${ACTION_GIT_REPO_PATH:-}" ]; then
  args+=("--git-repo-path=${ACTION_GIT_REPO_PATH}")
fi
if [ -n "${ACTION_GIT_BRANCH:-}" ]; then
  args+=("--git-branch=${ACTION_GIT_BRANCH}")
fi

export BIFROST_SERVER_URL="${ACTION_API_HOST}"
if [ -n "${ACTION_ORG_ID:-}" ]; then
  export BIFROST_ORG_ID="${ACTION_ORG_ID}"
else
  export BIFROST_API_KEY="${ACTION_API_TOKEN}"
fi

"${CLI_PATH}" "${args[@]}" sbom upload "${sbom_paths[@]}"
