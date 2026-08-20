#!/usr/bin/env bash

set -euo pipefail

cli_version="v0.3.1"

# Release asset and pinned checksum per runner platform; update together with cli_version.
case "${RUNNER_OS}:${RUNNER_ARCH}" in
  Linux:X64)
    asset_name="bifrost-linux-amd64"
    expected_sha="174d394a04eee09588127c871f84c608c14b7d3a1a70611b8b327cb017f27445"
    ;;
  Linux:ARM64)
    asset_name="bifrost-linux-arm64"
    expected_sha="0b7f4c61ee4ed810511479a93c9325c3f84dc99340b6375be97dc09603a440e5"
    ;;
  macOS:X64)
    asset_name="bifrost-darwin-amd64"
    expected_sha="3a4adb907487b56fb88c51b8546bf39031efd6d1cac0bef499db75eb1fe44f5d"
    ;;
  macOS:ARM64)
    asset_name="bifrost-darwin-arm64"
    expected_sha="89638d6465ca8af0846cded855e48b2d242d51f0e4c7522a69c660c63d3fd1dc"
    ;;
  Windows:X64)
    asset_name="bifrost-windows-amd64"
    expected_sha="7c7473ab0e209ea7a93e7f152d38e915a464eb317675788d931aefbf3f64df20"
    ;;
  Windows:X86)
    asset_name="bifrost-windows-386"
    expected_sha="6fafec53b0f796977eaabe3e2fea1d1d744fc39d18f8012cbe9734dfdab9a37c"
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
