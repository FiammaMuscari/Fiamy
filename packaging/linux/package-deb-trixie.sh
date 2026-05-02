#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="${FIAMY_TRIXIE_IMAGE:-debian:trixie}"
CONTAINER_TOOL="${CONTAINER_TOOL:-}"

if [[ -z "${CONTAINER_TOOL}" ]]; then
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_TOOL="podman"
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_TOOL="docker"
  else
    echo "No se encontró podman ni docker" >&2
    exit 1
  fi
fi

"${CONTAINER_TOOL}" run --rm \
  -v "${ROOT_DIR}:/src" \
  -w /src \
  "${IMAGE}" \
  bash -lc '
    set -euo pipefail
    apt-get update
    apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      dpkg-dev \
      file \
      ninja-build \
      pkg-config \
      qt6-base-dev \
      qt6-base-dev-tools \
      qt6-declarative-dev \
      qt6-multimedia-dev \
      qt6-tools-dev-tools \
      qt6-wayland \
      wget
    ./packaging/linux/package-deb.sh debian-trixie-bundled
  '
