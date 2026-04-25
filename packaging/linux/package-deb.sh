#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-release-linux"
DIST_DIR="${ROOT_DIR}/dist/linux-deb"
DISTRO_TAG="${1:-}"
VERSION="$(grep -oP 'project\(Fiamy VERSION \K[^ ]+' "${ROOT_DIR}/CMakeLists.txt" | head -1)"

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  ${DISTRO_TAG:+-DFIAMY_DEB_DISTRO_TAG="${DISTRO_TAG}"}

cmake --build "${BUILD_DIR}" --parallel
mkdir -p "${DIST_DIR}"
( cd "${BUILD_DIR}" && cpack -G DEB --output-file-prefix "${DIST_DIR}" )

if [[ -n "${DISTRO_TAG}" ]]; then
  ARCH="$(dpkg --print-architecture)"
  DEFAULT_DEB="${DIST_DIR}/fiamy_${VERSION}_${ARCH}.deb"
  TAGGED_DEB="${DIST_DIR}/fiamy_${VERSION}_${DISTRO_TAG}_${ARCH}.deb"
  if [[ -f "${DEFAULT_DEB}" ]]; then
    mv -f "${DEFAULT_DEB}" "${TAGGED_DEB}"
    echo "Renamed package to ${TAGGED_DEB}"
  fi
fi
