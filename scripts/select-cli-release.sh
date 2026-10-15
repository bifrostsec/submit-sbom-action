#!/usr/bin/env bash

set -euo pipefail

cli_version="v0.3.1"

# Select the asset and pinned checksum for this runner; update together with cli_version.
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

cli_dir="${RUNNER_TEMP}/bifrost-cli"
cli_path="${cli_dir}/${asset_name}"
if [ "${RUNNER_OS}" = "Windows" ]; then
  cli_path="${cli_path}.exe"
fi
download_url="https://github.com/bifrostsec/bifrost-cli/releases/download/${cli_version}/${asset_name}"
cache_key="bifrost-cli-${asset_name}-${expected_sha}"

export cli_path download_url expected_sha cache_key
