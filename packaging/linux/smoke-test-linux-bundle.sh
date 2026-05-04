#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <portable-dir-or-appimage>" >&2
  exit 1
fi

TARGET="$1"
TIMEOUT_SECONDS="${FIAMY_SMOKE_TIMEOUT_SECONDS:-8}"
LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/fiamy-smoke.XXXXXX.log")"

if [[ -d "${TARGET}" ]]; then
  RUNNER="${TARGET}/Fiamy.sh"
  if [[ ! -x "${RUNNER}" ]]; then
    echo "Portable runner not found or not executable: ${RUNNER}" >&2
    exit 1
  fi
elif [[ -f "${TARGET}" ]]; then
  RUNNER="${TARGET}"
  chmod +x "${RUNNER}"
  export APPIMAGE_EXTRACT_AND_RUN="${APPIMAGE_EXTRACT_AND_RUN:-1}"
else
  echo "Target not found: ${TARGET}" >&2
  exit 1
fi

set +e
QT_QPA_PLATFORM=offscreen timeout "${TIMEOUT_SECONDS}s" "${RUNNER}" >"${LOG_FILE}" 2>&1
status=$?
set -e

if grep -Eiq 'error while loading shared libraries|cannot open shared object file|Could not (find|load) the Qt platform plugin|No such file or directory|Fontconfig error: Cannot load default config file|QQmlApplicationEngine failed to load component' "${LOG_FILE}"; then
  cat "${LOG_FILE}" >&2
  echo "Smoke test failed: startup dependency/plugin error detected." >&2
  exit 1
fi

case "${status}" in
  0|124)
    echo "Smoke test passed for ${TARGET}"
    echo "Log: ${LOG_FILE}"
    ;;
  *)
    cat "${LOG_FILE}" >&2
    echo "Smoke test failed with exit code ${status}" >&2
    exit "${status}"
    ;;
esac
