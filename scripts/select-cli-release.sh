#!/usr/bin/env bash

set -euo pipefail

cli_version="v0.4.0"

# Select the asset and pinned checksum for this runner; update together with cli_version.
case "${RUNNER_OS}:${RUNNER_ARCH}" in
  Linux:X64)
    asset_name="bifrost-linux-amd64"
    expected_sha="6ddd19d1da298effa225858e7df96304d72cd780d289e9f9262eceab91840305"
    ;;
  Linux:ARM64)
    asset_name="bifrost-linux-arm64"
    expected_sha="c5e0be5a8e3a776df5a2a71ff9f4f0d5bae2cf1ee1da2620b811ef4bebe2dde4"
    ;;
  macOS:X64)
    asset_name="bifrost-darwin-amd64"
    expected_sha="df4bf2184a716973e933276bed784329a5eab2781a8fdd6cdf2d9dd40b371ca6"
    ;;
  macOS:ARM64)
    asset_name="bifrost-darwin-arm64"
    expected_sha="8dd2d22b22641f844e489fb08ecd17c6e58ad347fd5c2aea9f9b8902a81c29fa"
    ;;
  Windows:X64)
    asset_name="bifrost-windows-amd64"
    expected_sha="cb2767b5e3fb39f3c9af8217e2746bfaa2c39d7a7c2705603845929df2971d80"
    ;;
  Windows:X86)
    asset_name="bifrost-windows-386"
    expected_sha="d3dda514218760eff63d75c83b4d181e6f7b8be7094ca64238cc2bb21d69d531"
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
