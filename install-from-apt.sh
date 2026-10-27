#!/usr/bin/env bash
set -euo pipefail

repository_url="${WITVIA_APT_URL:-https://witcon-ab.github.io/WitVia-Packages}"
architecture="$(dpkg --print-architecture)"
if [[ "$architecture" != arm64 ]]; then
  echo "WitVia Core is currently published for arm64, not $architecture" >&2
  exit 1
fi
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run this installer with sudo." >&2
  exit 1
fi
. /etc/os-release
if [[ "${VERSION_ID%%.*}" -lt 13 ]]; then
  echo 'WitVia initial installation requires Debian 13 / Raspberry Pi OS Trixie or newer.' >&2
  exit 1
fi

temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
curl --fail --silent --show-error --location \
  "$repository_url/witvia-archive-keyring.gpg" \
  --output "$temporary/witvia-archive-keyring.gpg"
gpg --show-keys "$temporary/witvia-archive-keyring.gpg" >/dev/null
install -m 0644 "$temporary/witvia-archive-keyring.gpg" \
  /usr/share/keyrings/witvia-archive-keyring.gpg

sed "s|@REPOSITORY_URL@|$repository_url|g" > /etc/apt/sources.list.d/witvia.sources <<'EOF'
Types: deb
URIs: @REPOSITORY_URL@
Suites: stable
Components: main
Architectures: arm64
Signed-By: /usr/share/keyrings/witvia-archive-keyring.gpg
EOF

apt-get update
apt-get install -y witvia-core
echo "WitVia Edge is installed. Open https://$(hostname).local/ or the device IP."
