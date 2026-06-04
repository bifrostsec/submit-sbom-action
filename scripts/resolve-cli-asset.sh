#!/usr/bin/env bash

set -euo pipefail

# Resolve the release asset and pinned checksum from the GitHub runner platform.
case "${RUNNER_OS}:${RUNNER_ARCH}" in
  Linux:X64)
    asset_name="bifrost-linux-amd64"
    expected_sha="4b0ad5f0e6ab564d960341d6fcccb4a5325bbe199057c42f2eab0f317a1be35b"
    ;;
  Linux:ARM64)
    asset_name="bifrost-linux-arm64"
    expected_sha="d50083261ce9f279125c3e82243f2486049491e9332cd9e2cff8c4b4680021c0"
    ;;
  macOS:X64)
    asset_name="bifrost-darwin-amd64"
    expected_sha="26304992e59f93be5ffeee5f6b202034bb86c3816a84dbdb747ea9ddfe54ad5a"
    ;;
  macOS:ARM64)
    asset_name="bifrost-darwin-arm64"
    expected_sha="0fb881eb38233ad1cc76fb56df4b4effa3b5b3a3f30552eab887051af0fad42b"
    ;;
  Windows:X64)
    asset_name="bifrost-windows-amd64"
    expected_sha="9b19cb2ae3837e7155b062f8fafd9f02da74bc883820650e194dd23050f614fd"
    ;;
  Windows:X86)
    asset_name="bifrost-windows-386"
    expected_sha="0db9d185555d38bf2632ffc05f9a7478f40b18af3642d84b82f4d8c0326bad48"
    ;;
  *)
    echo "::error::Unsupported runner platform: ${RUNNER_OS}/${RUNNER_ARCH}"
    exit 1
    ;;
esac

echo "asset_name=${asset_name}" >> "${GITHUB_OUTPUT}"
echo "expected_sha=${expected_sha}" >> "${GITHUB_OUTPUT}"
