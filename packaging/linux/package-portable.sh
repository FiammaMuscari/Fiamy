#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-release-linux"
PORTABLE_DIR="${ROOT_DIR}/dist/fiamy-linux-portable"
ARCHIVE_DIR="${ROOT_DIR}/dist/linux-portable"
VERSION="${1:-$(grep -oP 'project\(Fiamy VERSION \K[^ ]+' "${ROOT_DIR}/CMakeLists.txt" | head -1)}"
ARCHIVE_BASENAME="fiamy-${VERSION}-linux-portable-x86_64"
YTDLP_BUNDLE="${ROOT_DIR}/dist/tools/yt-dlp_linux"

prepare_bundled_ytdlp() {
  if [[ -x "${YTDLP_BUNDLE}" ]]; then
    return
  fi

  mkdir -p "$(dirname "${YTDLP_BUNDLE}")"
  if command -v wget >/dev/null 2>&1; then
    echo "Downloading standalone yt-dlp for Linux bundle..."
    if wget -q -O "${YTDLP_BUNDLE}" \
      "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux"; then
      chmod +x "${YTDLP_BUNDLE}"
      return
    fi
  fi

  rm -f "${YTDLP_BUNDLE}"
  echo "Warning: standalone yt-dlp could not be downloaded; the app will download it on first use." >&2
}

prepare_bundled_ytdlp

CMAKE_ARGS=(-DCMAKE_BUILD_TYPE=Release)
if [[ -x "${YTDLP_BUNDLE}" ]]; then
  CMAKE_ARGS+=("-DFIAMY_BUNDLED_YT_DLP=${YTDLP_BUNDLE}")
fi

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" "${CMAKE_ARGS[@]}"

cmake --build "${BUILD_DIR}" --parallel

rm -rf "${PORTABLE_DIR}"
cmake --install "${BUILD_DIR}" --prefix "${PORTABLE_DIR}"

QT_PLUGIN_DIR="$(qtpaths6 --plugin-dir 2>/dev/null || qmake6 -query QT_INSTALL_PLUGINS 2>/dev/null || true)"
QT_QML_DIR="$(qtpaths6 --qml-dir 2>/dev/null || qmake6 -query QT_INSTALL_QML 2>/dev/null || true)"

copy_tree() {
  local src="$1"
  local dest="$2"
  if [[ -e "${src}" ]]; then
    mkdir -p "$(dirname "${dest}")"
    cp -aL "${src}" "${dest}"
  fi
}

copy_file_if_needed() {
  local src="$1"
  local dest_dir="$2"
  if [[ -e "${src}" ]]; then
    mkdir -p "${dest_dir}"
    cp -aL "${src}" "${dest_dir}/"
  fi
}

mapfile -t QT_RUNTIME_LIBS < <(
  ldd "${PORTABLE_DIR}/bin/fiamy" \
    | awk '/=>/ {print $3}' \
    | grep -E '^/(lib|usr/lib).*/libQt6.*\.so(\..*)?$' \
    | sort -u
)

for dep in "${QT_RUNTIME_LIBS[@]}"; do
  [[ -n "${dep}" ]] || continue
  copy_file_if_needed "${dep}" "${PORTABLE_DIR}/lib/x86_64-linux-gnu"
done

for plugin_subdir in platforms platforminputcontexts xcbglintegrations \
  wayland-decoration-client wayland-graphics-integration-client wayland-shell-integration \
  imageformats iconengines tls networkinformation multimedia; do
  copy_tree "${QT_PLUGIN_DIR}/${plugin_subdir}" \
    "${PORTABLE_DIR}/lib/x86_64-linux-gnu/qt6/plugins/${plugin_subdir}"
done

for qml_module in QtQml QtQuick QtMultimedia Qt/labs/platform; do
  copy_tree "${QT_QML_DIR}/${qml_module}" \
    "${PORTABLE_DIR}/lib/x86_64-linux-gnu/qt6/qml/${qml_module}"
done

"${ROOT_DIR}/packaging/linux/deploy-runtime-libs.sh" "${PORTABLE_DIR}"
"${ROOT_DIR}/packaging/linux/verify-linux-bundle.sh" "${PORTABLE_DIR}"

cat > "${PORTABLE_DIR}/Fiamy.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="${APPDIR}/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export QT_PLUGIN_PATH="${APPDIR}/lib/x86_64-linux-gnu/qt6/plugins${QT_PLUGIN_PATH:+:${QT_PLUGIN_PATH}}"
export QML2_IMPORT_PATH="${APPDIR}/lib/x86_64-linux-gnu/qt6/qml${QML2_IMPORT_PATH:+:${QML2_IMPORT_PATH}}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${APPDIR}/lib/x86_64-linux-gnu/qt6/plugins/platforms"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"

exec "${APPDIR}/bin/fiamy" "$@"
EOF
chmod +x "${PORTABLE_DIR}/Fiamy.sh"

mkdir -p "${ARCHIVE_DIR}"
tar -C "${ROOT_DIR}/dist" -czf "${ARCHIVE_DIR}/${ARCHIVE_BASENAME}.tar.gz" "$(basename "${PORTABLE_DIR}")"

echo "Portable folder: ${PORTABLE_DIR}"
echo "Portable archive: ${ARCHIVE_DIR}/${ARCHIVE_BASENAME}.tar.gz"
