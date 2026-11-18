#!/usr/bin/env bash

# Update the bifrost CLI release pinned in select-cli-release.sh together with
# the SHA-256 checksum of every release asset listed there.
#
#   scripts/update-cli-release.sh          # pin the latest release
#   scripts/update-cli-release.sh v0.4.0   # pin a specific release
#
# Requires curl and jq. Set GITHUB_TOKEN to raise the GitHub API rate limit.

set -euo pipefail

cli_repo="bifrostsec/bifrost-cli"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
release_script="${script_dir}/select-cli-release.sh"

for tool in curl jq; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "Error: ${tool} is required to update the bifrost CLI release" >&2
    exit 1
  fi
done

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

github_api() {
  local url="https://api.github.com/$1"
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl --fail --location --show-error --silent \
      -H "Accept: application/vnd.github+json" \
      -H @- \
      "${url}" \
      <<< "Authorization: Bearer ${GITHUB_TOKEN}"
  else
    curl --fail --location --show-error --silent \
      -H "Accept: application/vnd.github+json" \
      "${url}"
  fi
}

current_version="$(sed -nE 's/^cli_version="([^"]+)"$/\1/p' "${release_script}")"
if [ -z "${current_version}" ]; then
  echo "Error: could not find cli_version in ${release_script}" >&2
  exit 1
fi

target_version="${1:-}"
if [ -z "${target_version}" ]; then
  target_version="$(github_api "repos/${cli_repo}/releases/latest" | jq -er '.tag_name')"
  if [ "${target_version}" = "${current_version}" ]; then
    echo "bifrost CLI ${current_version} is already the latest release; nothing to update."
    exit 0
  fi
fi

echo "Updating bifrost CLI from ${current_version} to ${target_version}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# Download every asset the release script knows about and record its checksum.
# Assets that the release script does not list yet must be added by hand.
checksums=""
asset_count=0
while IFS= read -r asset_name; do
  url="https://github.com/${cli_repo}/releases/download/${target_version}/${asset_name}"
  echo "Downloading ${url}"
  curl --fail --location --show-error --silent --output "${tmp_dir}/${asset_name}" "${url}"
  sha="$(sha256 "${tmp_dir}/${asset_name}")"
  echo "  sha256 ${sha}"
  checksums+="${asset_name}=${sha} "
  asset_count=$((asset_count + 1))
done < <(sed -nE 's/^[[:space:]]*asset_name="([^"]+)"$/\1/p' "${release_script}")

if [ "${asset_count}" -eq 0 ]; then
  echo "Error: no asset_name entries found in ${release_script}" >&2
  exit 1
fi

# Rewrite cli_version and each expected_sha, matched to the asset_name above it.
# The checksums are passed as space-separated "asset=sha" pairs because BSD awk
# rejects -v values that contain newlines.
awk -v version="${target_version}" -v checksums="${checksums}" '
BEGIN {
  n = split(checksums, pairs, " ")
  for (i = 1; i <= n; i++) {
    if (split(pairs[i], kv, "=") == 2) {
      sha[kv[1]] = kv[2]
    }
  }
}
/^cli_version="/ {
  $0 = "cli_version=\"" version "\""
}
/^[[:space:]]*asset_name="/ {
  asset = $0
  sub(/^[^"]*"/, "", asset)
  sub(/".*$/, "", asset)
}
/^[[:space:]]*expected_sha="/ {
  if (!(asset in sha)) {
    print "Error: no checksum downloaded for asset " asset > "/dev/stderr"
    exit 1
  }
  sub(/"[^"]*"/, "\"" sha[asset] "\"")
  replaced++
}
{ print }
END {
  if (replaced != length(sha)) {
    print "Error: replaced " replaced " checksums but downloaded " length(sha) > "/dev/stderr"
    exit 1
  }
}
' "${release_script}" > "${tmp_dir}/select-cli-release.sh"

# Overwrite in place to keep the file mode.
cat "${tmp_dir}/select-cli-release.sh" > "${release_script}"
bash -n "${release_script}"

echo "Pinned bifrost CLI ${target_version} with ${asset_count} checksums in ${release_script}"
echo "Review the change with: git diff -- ${release_script#"$(pwd)/"}"
