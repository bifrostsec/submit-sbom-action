#!/usr/bin/env bash

set -euo pipefail

if command -v sha256sum >/dev/null 2>&1; then
  actual_sha="$(sha256sum "${CLI_PATH}" | awk '{print $1}')"
else
  actual_sha="$(shasum -a 256 "${CLI_PATH}" | awk '{print $1}')"
fi

if [ "${actual_sha}" != "${CLI_EXPECTED_SHA}" ]; then
  echo "Checksum mismatch for ${CLI_PATH}" >&2
  exit 1
fi

chmod +x "${CLI_PATH}"
