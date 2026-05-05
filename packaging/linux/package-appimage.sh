#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${1:-$(grep -oP 'project\(Fiamy VERSION \K[^ ]+' "${ROOT_DIR}/CMakeLists.txt" | head -1)}"
APPDIR="${ROOT_DIR}/dist/appimage/Fiamy.AppDir"
OUTPUT_DIR="${ROOT_DIR}/dist/linux-appimage"
APPIMAGE_NAME="Fiamy-${VERSION}-x86_64.AppImage"
PORTABLE_DIR="${ROOT_DIR}/dist/fiamy-linux-portable"
APPIMAGETOOL="${APPIMAGETOOL:-}"
APPIMAGE_RUNTIME="${APPIMAGE_RUNTIME:-${ROOT_DIR}/dist/tools/runtime-x86_64}"

if [[ "${FIAMY_SKIP_PORTABLE_BUILD:-0}" != "1" ]]; then
  "${ROOT_DIR}/packaging/linux/package-portable.sh" "${VERSION}"
elif [[ ! -x "${PORTABLE_DIR}/Fiamy.sh" ]]; then
  echo "FIAMY_SKIP_PORTABLE_BUILD=1 was set, but ${PORTABLE_DIR} is not ready." >&2
  exit 1
fi

rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr"
cp -a "${PORTABLE_DIR}/." "${APPDIR}/usr/"
mkdir -p "${APPDIR}/usr/etc/fonts"
cat > "${APPDIR}/usr/etc/fonts/fonts.conf" <<'EOF'
<?xml version="1.0"?>
<fontconfig>
  <description>Fiamy bundled fontconfig runtime</description>
  <!--
    The AppImage copies the whole portable bundle under AppDir/usr.
    Portable fonts therefore live at:
      AppDir/usr/usr/share/fonts
    Keep this path aligned with package-portable.sh, otherwise Qt starts with
    no usable bundled fonts and QML text/icons render as tofu squares.
  -->
  <dir prefix="relative">../../usr/share/fonts</dir>
  <cachedir prefix="xdg">fontconfig</cachedir>
  <cachedir>~/.fontconfig</cachedir>
  <config>
    <rescan>
      <int>30</int>
    </rescan>
  </config>
</fontconfig>
EOF

cat > "${APPDIR}/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${APPDIR}/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export QT_PLUGIN_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu/qt6/plugins${QT_PLUGIN_PATH:+:${QT_PLUGIN_PATH}}"
export QML2_IMPORT_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu/qt6/qml${QML2_IMPORT_PATH:+:${QML2_IMPORT_PATH}}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu/qt6/plugins/platforms"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
export FONTCONFIG_PATH="${APPDIR}/usr/etc/fonts"
export FONTCONFIG_FILE="${APPDIR}/usr/etc/fonts/fonts.conf"
export XDG_DATA_DIRS="${APPDIR}/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-software}"

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
cp -a "${ROOT_DIR}/fiamy.svg" "${APPDIR}/fiamy.svg"
"${ROOT_DIR}/packaging/linux/verify-linux-bundle.sh" "${APPDIR}/usr"

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

prepare_runtime_file() {
  if [[ -s "${APPIMAGE_RUNTIME}" ]]; then
    return
  fi

  local existing_appimage="${OUTPUT_DIR}/${APPIMAGE_NAME}"
  if [[ ! -x "${existing_appimage}" ]]; then
    return
  fi

  local offset
  offset="$("${existing_appimage}" --appimage-offset 2>/dev/null || true)"
  if [[ "${offset}" =~ ^[0-9]+$ && "${offset}" -gt 0 ]]; then
    mkdir -p "$(dirname "${APPIMAGE_RUNTIME}")"
    dd if="${existing_appimage}" of="${APPIMAGE_RUNTIME}" bs=1 count="${offset}" status=none
    chmod +x "${APPIMAGE_RUNTIME}"
    echo "Extracted AppImage runtime from existing ${existing_appimage}" >&2
  fi
}

prepare_runtime_file

APPIMAGETOOL_ARGS=()
if [[ -s "${APPIMAGE_RUNTIME}" ]]; then
  APPIMAGETOOL_ARGS+=(--runtime-file "${APPIMAGE_RUNTIME}")
fi
APPIMAGETOOL_ARGS+=("${APPDIR}" "${OUTPUT_DIR}/${APPIMAGE_NAME}")

if ! ARCH=x86_64 "${APPIMAGETOOL}" "${APPIMAGETOOL_ARGS[@]}"; then
  echo "appimagetool could not run through FUSE; retrying with AppImage extract-and-run fallback..." >&2
  ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "${APPIMAGETOOL}" "${APPIMAGETOOL_ARGS[@]}"
fi

echo "AppImage: ${OUTPUT_DIR}/${APPIMAGE_NAME}"
