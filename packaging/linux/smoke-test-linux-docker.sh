#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <artifacts-dir>" >&2
  exit 1
fi

ARTIFACTS_DIR="$(cd "$1" && pwd)"
IMAGE="${FIAMY_DOCKER_IMAGE:-ubuntu:22.04}"
FAIL_PATTERN='Fontconfig error: Cannot load default config file|QQmlApplicationEngine failed to load component|error while loading shared libraries|cannot open shared object file|GLIBC_[0-9]+\.[0-9]+|MOUNT_[0-9_]+'

run_check() {
  local name="$1"
  local cmd="$2"

  echo "== Docker smoke test: ${name} ==" >&2
  local output
  output="$(docker run --rm -v "${ARTIFACTS_DIR}:/app" "${IMAGE}" bash -lc "${cmd}" 2>&1 || true)"
  printf '%s\n' "${output}"

  if grep -Eiq "${FAIL_PATTERN}" <<<"${output}"; then
    echo "Docker smoke test failed for ${name}" >&2
    exit 1
  fi
}

run_check "AppImage" '
  apt update >/dev/null &&
  cd /app &&
  chmod +x Fiamy-*.AppImage &&
  QT_QPA_PLATFORM=offscreen ./Fiamy-*.AppImage --appimage-extract-and-run
'

run_check "portable" '
  apt update >/dev/null &&
  cd /app &&
  tar -xzf fiamy-*-linux-portable-x86_64.tar.gz >/dev/null 2>&1 &&
  QT_QPA_PLATFORM=offscreen ./fiamy-linux-portable/Fiamy.sh
'

run_check ".deb" '
  apt update >/dev/null &&
  apt install -y /app/fiamy_*_ubuntu-debian-bundled_amd64.deb >/dev/null &&
  QT_QPA_PLATFORM=offscreen fiamy
'

echo "Docker smoke tests passed."
