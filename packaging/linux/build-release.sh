#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build-release-linux"
YTDLP_BIN="$(command -v yt-dlp || true)"

echo "🐧 Configurando release en: $BUILD_DIR"
mkdir -p "$BUILD_DIR"

if [[ -n "$YTDLP_BIN" ]]; then
  cp "$YTDLP_BIN" "$BUILD_DIR/yt-dlp"
  chmod +x "$BUILD_DIR/yt-dlp"
  echo "📦 Bundled yt-dlp from: $YTDLP_BIN"
else
  echo "⚠️ yt-dlp not found in PATH; package will fall back to first-run download"
fi

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr

echo "🛠️ Compilando Fiamy..."
cmake --build "$BUILD_DIR" -j"$(nproc)"

echo "✅ Build release listo"
echo "📦 Binario esperado: $BUILD_DIR/fiamy"
