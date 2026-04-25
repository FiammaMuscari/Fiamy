#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${1:-$(grep -oP 'project\(Fiamy VERSION \K[^ ]+' "${ROOT_DIR}/CMakeLists.txt" | head -1)}"
APPDIR="${ROOT_DIR}/dist/appimage/Fiamy.AppDir"
OUTPUT_DIR="${ROOT_DIR}/dist/linux-appimage"
APPIMAGE_NAME="Fiamy-${VERSION}-x86_64.AppImage"
PORTABLE_DIR="${ROOT_DIR}/dist/fiamy-linux-portable"
APPIMAGETOOL="${APPIMAGETOOL:-}"

"${ROOT_DIR}/packaging/linux/package-portable.sh" "${VERSION}"

rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr"
cp -a "${PORTABLE_DIR}/." "${APPDIR}/usr/"

cat > "${APPDIR}/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export QT_PLUGIN_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu/qt6/plugins${QT_PLUGIN_PATH:+:${QT_PLUGIN_PATH}}"
export QML2_IMPORT_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu/qt6/qml${QML2_IMPORT_PATH:+:${QML2_IMPORT_PATH}}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu/qt6/plugins/platforms"

exec "${APPDIR}/usr/bin/fiamy" "$@"
EOF
chmod +x "${APPDIR}/AppRun"

cat > "${APPDIR}/fiamy.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Fiamy
Comment=Fiamy MP3 and YouTube player
Exec=fiamy
Icon=fiamy
Terminal=false
Categories=AudioVideo;Audio;Player;
StartupNotify=true
EOF

cp -a "${ROOT_DIR}/pink.png" "${APPDIR}/fiamy.png"

if [[ -z "${APPIMAGETOOL}" ]]; then
  APPIMAGETOOL="${ROOT_DIR}/dist/tools/appimagetool-x86_64.AppImage"
fi

if [[ ! -x "${APPIMAGETOOL}" ]]; then
  mkdir -p "${ROOT_DIR}/dist/tools"
  wget -O "${APPIMAGETOOL}" \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x "${APPIMAGETOOL}"
fi

mkdir -p "${OUTPUT_DIR}"
ARCH=x86_64 "${APPIMAGETOOL}" "${APPDIR}" "${OUTPUT_DIR}/${APPIMAGE_NAME}"

echo "AppImage: ${OUTPUT_DIR}/${APPIMAGE_NAME}"
