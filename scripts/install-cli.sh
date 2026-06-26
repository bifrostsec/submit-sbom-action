#!/usr/bin/env bash

set -euo pipefail

cli_version="v0.2.1"

# Release asset and pinned checksum per runner platform; update together with cli_version.
case "${RUNNER_OS}:${RUNNER_ARCH}" in
  Linux:X64)
    asset_name="bifrost-linux-amd64"
    expected_sha="18b1237f8b6f17325f0a9a04f8438fee3033e8d48eebc475bb5a54bcad1f5038"
    ;;
  Linux:ARM64)
    asset_name="bifrost-linux-arm64"
    expected_sha="cf4cf543af9f0e075ad064e6d8354dc4ff57b214fa93136495d68a75915879af"
    ;;
  macOS:X64)
    asset_name="bifrost-darwin-amd64"
    expected_sha="112a788b5bfef7c288453461769d8731fba69ef0271ca03a734d8ae03bba4310"
    ;;
  macOS:ARM64)
    asset_name="bifrost-darwin-arm64"
    expected_sha="f58def0f31d2388ec61217d2352cccfcf59ba95cb35c5249f688e78658914fb0"
    ;;
  Windows:X64)
    asset_name="bifrost-windows-amd64"
    expected_sha="02dc33c94cf43b47c9b65d0d0086ddc282be46247d90c166ac916dc360be13c6"
    ;;
  Windows:X86)
    asset_name="bifrost-windows-386"
    expected_sha="d5203ece4d5ad7961482faf6fb9f7901f713061462f3ba6490236a297a77af30"
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
