#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build-release-linux"
DIST_DIR="$ROOT_DIR/dist/linux-deb"

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "⚠️ Build directory not found."
  echo "Run: ./packaging/linux/build-release.sh"
  exit 1
fi

echo "📦 Building DEB package..."
mkdir -p "$DIST_DIR"

cmake --build "$BUILD_DIR" -j"$(nproc)"
cpack --config "$BUILD_DIR/CPackConfig.cmake" -G DEB --verbose -B "$DIST_DIR"

echo "✅ Debian package created in: $DIST_DIR"
