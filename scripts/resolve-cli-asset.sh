#!/usr/bin/env bash

set -euo pipefail

# Resolve the release asset and pinned checksum from the GitHub runner platform.
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

echo "asset_name=${asset_name}" >> "${GITHUB_OUTPUT}"
echo "expected_sha=${expected_sha}" >> "${GITHUB_OUTPUT}"
