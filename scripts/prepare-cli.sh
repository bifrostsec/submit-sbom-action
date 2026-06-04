#!/usr/bin/env bash

set -euo pipefail

# Normalize the downloaded file path, verify it, and return the executable path.
cli_path="${CLI_DOWNLOAD_DIR}/${ASSET_NAME}"
if [ "${RUNNER_OS}" = "Windows" ]; then
  mv "${cli_path}" "${cli_path}.exe"
  cli_path="${cli_path}.exe"
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual_sha="$(sha256sum "${cli_path}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual_sha="$(shasum -a 256 "${cli_path}" | awk '{print $1}')"
elif command -v openssl >/dev/null 2>&1; then
  actual_sha="$(openssl dgst -sha256 "${cli_path}" | awk '{print $NF}')"
else
  echo "::error::No SHA-256 tool found on runner"
  exit 1
fi

if [ "${actual_sha}" != "${EXPECTED_SHA}" ]; then
  echo "::error::Checksum mismatch for ${ASSET_NAME}"
  exit 1
fi

chmod +x "${cli_path}"
echo "cli_path=${cli_path}" >> "${GITHUB_OUTPUT}"
