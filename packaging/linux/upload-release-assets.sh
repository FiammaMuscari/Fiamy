#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <tag-del-release>" >&2
  exit 1
fi

TAG="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(grep -oP 'project\(Fiamy VERSION \K[^ ]+' "${ROOT_DIR}/CMakeLists.txt" | head -1)"
DEB_TAG="${FIAMY_DEB_TAG:-ubuntu-debian-bundled}"
ARCH="${FIAMY_DEB_ARCH:-amd64}"

APPIMAGE="${ROOT_DIR}/dist/linux-appimage/Fiamy-${VERSION}-x86_64.AppImage"
PORTABLE="${ROOT_DIR}/dist/linux-portable/fiamy-${VERSION}-linux-portable-x86_64.tar.gz"
DEB="${ROOT_DIR}/dist/linux-deb/fiamy_${VERSION}_${DEB_TAG}_${ARCH}.deb"
CHECKSUMS="${ROOT_DIR}/dist/linux-sha256sums.txt"

for asset in "${APPIMAGE}" "${PORTABLE}" "${DEB}" "${CHECKSUMS}"; do
  if [[ ! -f "${asset}" ]]; then
    echo "Missing release asset: ${asset}" >&2
    exit 1
  fi
done

gh release upload "${TAG}" --clobber \
  "${APPIMAGE}" \
  "${PORTABLE}" \
  "${DEB}" \
  "${CHECKSUMS}" \
  --repo FiammaMuscari/Fiamy
