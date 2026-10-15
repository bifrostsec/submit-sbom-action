#!/usr/bin/env bash

set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
  echo "::error::curl is required to download the Bifrost CLI"
  exit 1
fi

mkdir -p "$(dirname "${CLI_PATH}")"
curl --fail --location --show-error --silent \
  --retry 7 \
  --retry-connrefused \
  --output "${CLI_PATH}" \
  "${CLI_DOWNLOAD_URL}"
