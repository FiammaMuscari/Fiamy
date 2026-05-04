#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <artifacts-dir>" >&2
  exit 1
fi

ARTIFACTS_DIR="$(cd "$1" && pwd)"
IMAGE="${FIAMY_DOCKER_IMAGE:-ubuntu:22.04}"
TIMEOUT_SECONDS="${FIAMY_DOCKER_SMOKE_TIMEOUT_SECONDS:-20}"
FAIL_PATTERN='Fontconfig error: Cannot load default config file|QQmlApplicationEngine failed to load component|error while loading shared libraries|cannot open shared object file|GLIBC_[0-9]+\.[0-9]+|MOUNT_[0-9_]+|Unsupported file|cannot access'

run_check() {
  local name="$1"
  local cmd="$2"

  echo "== Docker smoke test: ${name} ==" >&2
  local output
  local status=0
  set +e
  output="$(timeout "${TIMEOUT_SECONDS}s" docker run --rm -v "${ARTIFACTS_DIR}:/app" "${IMAGE}" bash -lc "${cmd}" 2>&1)"
  status=$?
  set -e
  printf '%s\n' "${output}"

  if [[ "${status}" -ne 0 && "${status}" -ne 124 ]]; then
    echo "Docker smoke test exited with status ${status} for ${name}" >&2
    exit "${status}"
  fi

  if grep -Eiq "${FAIL_PATTERN}" <<<"${output}"; then
    echo "Docker smoke test failed for ${name}" >&2
    exit 1
  fi
}

run_check "AppImage" '
  apt update >/dev/null &&
  cd /app &&
  appimage=$(echo /app/linux-appimage/Fiamy-*.AppImage) &&
  [ "${appimage}" != "/app/linux-appimage/Fiamy-*.AppImage" ] &&
  chmod +x "${appimage}" &&
  rm -rf /app/squashfs-root &&
  "${appimage}" --appimage-extract >/dev/null &&
  test -f /app/squashfs-root/usr/lib/x86_64-linux-gnu/qt6/qml/Fiamy/qmldir &&
  QT_QPA_PLATFORM=offscreen QML_IMPORT_TRACE=1 /app/squashfs-root/AppRun
'

run_check "portable" '
  apt update >/dev/null &&
  cd /app &&
  archive=$(echo /app/linux-portable/fiamy-*-linux-portable-x86_64.tar.gz) &&
  [ "${archive}" != "/app/linux-portable/fiamy-*-linux-portable-x86_64.tar.gz" ] &&
  tar -xzf "${archive}" >/dev/null 2>&1 &&
  QT_QPA_PLATFORM=offscreen ./fiamy-linux-portable/Fiamy.sh
'

run_check ".deb" '
  apt update >/dev/null &&
  deb=$(echo /app/linux-deb/fiamy_*_ubuntu-debian-bundled_amd64.deb) &&
  [ "${deb}" != "/app/linux-deb/fiamy_*_ubuntu-debian-bundled_amd64.deb" ] &&
  apt install -y "${deb}" >/dev/null &&
  QT_QPA_PLATFORM=offscreen fiamy
'

echo "Docker smoke tests passed."
