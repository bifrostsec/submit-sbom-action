#!/usr/bin/env bash

set -euo pipefail

cli_version="v0.2.2"

# Release asset and pinned checksum per runner platform; update together with cli_version.
case "${RUNNER_OS}:${RUNNER_ARCH}" in
  Linux:X64)
    asset_name="bifrost-linux-amd64"
    expected_sha="516eaf892818d6a5f406dd10ce44ccd5b68546399b705d9dc0d5b711d2f4b9d1"
    ;;
  Linux:ARM64)
    asset_name="bifrost-linux-arm64"
    expected_sha="73aa3e3e20d1aa5bcd09740074503fd32b49bb05c8d935dbf099b602475628c1"
    ;;
  macOS:X64)
    asset_name="bifrost-darwin-amd64"
    expected_sha="7c494b2bc4036d1fe90a7f75a7d2b6377bd7185ed8c80f9095bae405438901f6"
    ;;
  macOS:ARM64)
    asset_name="bifrost-darwin-arm64"
    expected_sha="ca57a447c399340349ef9530ee5874350178d834671b5207d1bd918861c6e5bb"
    ;;
  Windows:X64)
    asset_name="bifrost-windows-amd64"
    expected_sha="7b1c340b963bd37353849041ea0ab4e7a65a1fa00c3a8bb92327ab2ca4b1abaa"
    ;;
  Windows:X86)
    asset_name="bifrost-windows-386"
    expected_sha="b109c58a683061b55fc8dc7e04e1bc5691e0f15f256f204ce87136168eb41c83"
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
