#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build-release-linux"
DIST_DIR="$ROOT_DIR/dist/fiamy-linux-portable"

if [[ ! -x "$BUILD_DIR/fiamy" ]]; then
  echo "⚠️ No encontré $BUILD_DIR/fiamy"
  echo "Primero ejecuta: ./packaging/linux/build-release.sh"
  exit 1
fi

echo "📁 Preparando carpeta portable..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

cp "$BUILD_DIR/fiamy" "$DIST_DIR/"

if [[ -f "$ROOT_DIR/pink.png" ]]; then
  cp "$ROOT_DIR/pink.png" "$DIST_DIR/"
fi

if [[ -f "$ROOT_DIR/pink.ico" ]]; then
  cp "$ROOT_DIR/pink.ico" "$DIST_DIR/"
fi

cat > "$DIST_DIR/README.txt" <<'EOF'
Fiamy Linux Portable
====================

Esta carpeta es una base inicial portable.

Todavía puede requerir:
- librerías Qt6 del sistema
- plugins multimedia
- ajustes adicionales para distribución final

Próximo paso recomendado:
- probar el binario
- luego decidir si empaquetar como AppImage o .deb
EOF

echo "✅ Carpeta portable creada en: $DIST_DIR"
