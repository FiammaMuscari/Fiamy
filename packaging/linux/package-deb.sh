#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist/linux-deb"
PKG_ROOT="${ROOT_DIR}/dist/deb-package-root"
PORTABLE_DIR="${ROOT_DIR}/dist/fiamy-linux-portable"
DISTRO_TAG="${1:-ubuntu-debian-bundled}"
VERSION="$(grep -oP 'project\(Fiamy VERSION \K[^ ]+' "${ROOT_DIR}/CMakeLists.txt" | head -1)"
ARCH="$(dpkg --print-architecture 2>/dev/null || echo amd64)"
DISTRO_TAG_SAFE="$(printf '%s' "${DISTRO_TAG}" | sed -E 's/[^A-Za-z0-9.+-]+/-/g')"
DEB_NAME="fiamy_${VERSION}_${DISTRO_TAG_SAFE}_${ARCH}.deb"

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "dpkg-deb is required to build the Debian package." >&2
  exit 1
fi

if [[ "${FIAMY_SKIP_PORTABLE_BUILD:-0}" != "1" ]]; then
  "${ROOT_DIR}/packaging/linux/package-portable.sh" "${VERSION}"
elif [[ ! -x "${PORTABLE_DIR}/Fiamy.sh" ]]; then
  echo "FIAMY_SKIP_PORTABLE_BUILD=1 was set, but ${PORTABLE_DIR} is not ready." >&2
  exit 1
fi

rm -rf "${PKG_ROOT}"
mkdir -p \
  "${PKG_ROOT}/DEBIAN" \
  "${PKG_ROOT}/opt" \
  "${PKG_ROOT}/usr/bin" \
  "${PKG_ROOT}/usr/share/applications" \
  "${PKG_ROOT}/usr/share/icons/hicolor/256x256/apps"

cp -a "${PORTABLE_DIR}" "${PKG_ROOT}/opt/fiamy"

cat > "${PKG_ROOT}/usr/bin/fiamy" <<'EOF'
#!/usr/bin/env bash
exec /opt/fiamy/Fiamy.sh "$@"
EOF
chmod +x "${PKG_ROOT}/usr/bin/fiamy"

cat > "${PKG_ROOT}/usr/share/applications/fiamy.desktop" <<'EOF'
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

cp -a "${ROOT_DIR}/pink.png" "${PKG_ROOT}/usr/share/icons/hicolor/256x256/apps/fiamy.png"

cat > "${PKG_ROOT}/DEBIAN/control" <<EOF
Package: fiamy
Version: ${VERSION}
Section: multimedia
Priority: optional
Architecture: ${ARCH}
Maintainer: fiammamuscari <fiammamuscari@gmail.com>
Depends: libc6 (>= 2.35), libgl1, libegl1, libx11-6, libxcb1, libdbus-1-3
Description: Fiamy MP3 and YouTube player
 A lightweight desktop MP3 and YouTube player built with Qt/QML.
 This package installs Fiamy under /opt/fiamy with a private bundled Qt runtime.
EOF

cat > "${PKG_ROOT}/DEBIAN/postinst" <<'EOF'
#!/usr/bin/env bash
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
EOF
chmod 0755 "${PKG_ROOT}/DEBIAN/postinst"

cat > "${PKG_ROOT}/DEBIAN/postrm" <<'EOF'
#!/usr/bin/env bash
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
EOF
chmod 0755 "${PKG_ROOT}/DEBIAN/postrm"

mkdir -p "${DIST_DIR}"
dpkg-deb --build --root-owner-group "${PKG_ROOT}" "${DIST_DIR}/${DEB_NAME}"

echo "Debian package: ${DIST_DIR}/${DEB_NAME}"
