#!/usr/bin/env bash

set -euo pipefail

cli_version="v0.2.0"

# Release asset and pinned checksum per runner platform; update together with cli_version.
case "${RUNNER_OS}:${RUNNER_ARCH}" in
  Linux:X64)
    asset_name="bifrost-linux-amd64"
    expected_sha="cf31d0de9a828267560bcb691cf162f36411f326d1d6b3562fe67bc038276a6b"
    ;;
  Linux:ARM64)
    asset_name="bifrost-linux-arm64"
    expected_sha="8de27c9e9d440bf7869c3d559d57b4ae17487b14ecce6cdcd9e3e0d07b46003c"
    ;;
  macOS:X64)
    asset_name="bifrost-darwin-amd64"
    expected_sha="f66714360ff3dfba26844874d32c96c3fb264b2e8d6c2f0d3ccb195178868439"
    ;;
  macOS:ARM64)
    asset_name="bifrost-darwin-arm64"
    expected_sha="c1b4245754892a0ab5454b42ee23aa8155bf9edd1199f74b22783083e081d626"
    ;;
  Windows:X64)
    asset_name="bifrost-windows-amd64"
    expected_sha="4de48dbe4a95ee1d5fd7d1051a0394efb87570970e8ade801e112b34ff59a1ef"
    ;;
  Windows:X86)
    asset_name="bifrost-windows-386"
    expected_sha="6ce43b29f636e00a13e3d6282bc2af18c22f2b2706dc8e2ac8dc9ffb8e11103a"
    ;;
  *)
    echo "::error::Unsupported runner platform: ${RUNNER_OS}/${RUNNER_ARCH}"
    exit 1
    ;;
esac

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::GitHub CLI (gh) is required to download the Bifrost CLI"
  exit 1
fi

cli_dir="${RUNNER_TEMP}/bifrost-cli"
mkdir -p "${cli_dir}"
gh release download "${cli_version}" \
  --repo bifrostsec/bifrost-cli \
  --pattern "${asset_name}" \
  --dir "${cli_dir}" \
  --clobber

cli_path="${cli_dir}/${asset_name}"
if [ "${RUNNER_OS}" = "Windows" ]; then
  mv "${cli_path}" "${cli_path}.exe"
  cli_path="${cli_path}.exe"
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual_sha="$(sha256sum "${cli_path}" | awk '{print $1}')"
else
  actual_sha="$(shasum -a 256 "${cli_path}" | awk '{print $1}')"
fi

if [ "${actual_sha}" != "${expected_sha}" ]; then
  echo "::error::Checksum mismatch for ${asset_name}"
  exit 1
fi

chmod +x "${cli_path}"
echo "cli_path=${cli_path}" >> "${GITHUB_OUTPUT}"
