#!/usr/bin/env bash

set -euo pipefail

# Validate the authentication inputs before any network access, so that a
# misconfigured workflow fails before the dependency graph export and the CLI
# download. The CLI authenticates with either a bifrost API token or the GitHub
# OIDC token of the job, which it exchanges for a short-lived access token when
# given an organization id.

if [ -n "${ACTION_API_TOKEN:-}" ] && [ -n "${ACTION_ORG_ID:-}" ]; then
  echo "::error::Provide either api-token or org-id, not both. Use api-token to authenticate with a bifrost API token, or org-id to authenticate with the GitHub OIDC token of the job."
  exit 1
fi

if [ -z "${ACTION_API_TOKEN:-}" ] && [ -z "${ACTION_ORG_ID:-}" ]; then
  echo "::error::Either api-token or org-id must be provided. Use api-token to authenticate with a bifrost API token, or org-id to authenticate with the GitHub OIDC token of the job."
  exit 1
fi

if [ -n "${ACTION_ORG_ID:-}" ] && { [ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ] || [ -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]; }; then
  echo "::error::GitHub OIDC authentication with org-id requires the job to grant the id-token: write permission. GitHub does not make an OIDC token available to workflows triggered by pull requests from forked repositories."
  exit 1
fi
