#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <AppImage-or-extracted-AppDir> [max-glibc-version]" >&2
  exit 1
fi

TARGET="$1"
MAX_GLIBC_VERSION="${2:-${FIAMY_MAX_GLIBC_VERSION:-2.35}}"
WORK_DIR=""
CLEAN_WORK_DIR=0

if [[ -f "${TARGET}" ]]; then
  TARGET="$(cd "$(dirname "${TARGET}")" && pwd)/$(basename "${TARGET}")"
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fiamy-appimage-audit.XXXXXX")"
  CLEAN_WORK_DIR=1
  chmod +x "${TARGET}"
  (
    cd "${WORK_DIR}"
    "${TARGET}" --appimage-extract >/dev/null
  )
  APPDIR="${WORK_DIR}/squashfs-root"
elif [[ -d "${TARGET}" ]]; then
  APPDIR="$(cd "${TARGET}" && pwd)"
else
  echo "Target not found: ${TARGET}" >&2
  exit 1
fi

cleanup() {
  if [[ "${CLEAN_WORK_DIR}" -eq 1 && "${FIAMY_KEEP_AUDIT_DIR:-0}" != "1" ]]; then
    rm -rf "${WORK_DIR}"
  fi
}
trap cleanup EXIT

if [[ ! -d "${APPDIR}" ]]; then
  echo "Extracted AppDir not found: ${APPDIR}" >&2
  exit 1
fi

is_elf() {
  local file_path="$1"
  [[ -f "${file_path}" ]] || return 1
  file -Lb "${file_path}" 2>/dev/null | grep -q "ELF"
}

echo "Auditing AppDir: ${APPDIR}"

checked=0
missing_log="$(mktemp "${TMPDIR:-/tmp}/fiamy-missing.XXXXXX.log")"
glibc_log="$(mktemp "${TMPDIR:-/tmp}/fiamy-glibc.XXXXXX.log")"
trap 'rm -f "${missing_log}" "${glibc_log}"; cleanup' EXIT

check_ldd_output() {
  local elf="$1"
  local output
  output="$(
    LD_LIBRARY_PATH="${APPDIR}/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" \
      ldd "${elf}" 2>&1 || true
  )"

  if grep -Eq '=>[[:space:]]+not found|version `[^`]+` not found|cannot open shared object file' <<<"${output}"; then
    {
      echo
      echo "Dependency errors for: ${elf#${APPDIR}/}"
      echo "${output}"
    } >> "${missing_log}"
  fi
}

while IFS= read -r -d '' file; do
  if is_elf "${file}"; then
    checked=$((checked + 1))
    check_ldd_output "${file}"
  fi
done < <(
  find "${APPDIR}" -type f \( -perm -111 -o -name "*.so*" \) -print0
)

if [[ "${checked}" -eq 0 ]]; then
  echo "No ELF files found in AppDir." >&2
  exit 1
fi

if [[ -s "${missing_log}" ]]; then
  cat "${missing_log}" >&2
  echo "AppImage audit failed: missing runtime dependencies found." >&2
  exit 1
fi

while IFS= read -r -d '' file; do
  base="${file##*/}"
  case "${base}" in
    ld-linux*.so*|libBrokenLocale.so*|libSegFault.so*|\
    libc.so*|libpthread.so*|libdl.so*|librt.so*|libm.so*|libmvec.so*|\
    libutil.so*|libanl.so*|libresolv.so*|libnss_*.so*|libcrypt.so*|libthread_db.so*)
      echo "${file#${APPDIR}/}" >> "${glibc_log}"
      ;;
  esac
done < <(
  find "${APPDIR}" \( -type f -o -type l \) -print0
)

if [[ -s "${glibc_log}" ]]; then
  echo "AppImage audit failed: forbidden glibc/loader components are bundled:" >&2
  sort -u "${glibc_log}" >&2
  exit 1
fi

glibc_versions="$(
  find "${APPDIR}" -type f \( -perm -111 -o -name "*.so*" \) -print0 \
    | while IFS= read -r -d '' file; do
        if is_elf "${file}"; then
          strings "${file}" | grep -o 'GLIBC_[0-9]\+\.[0-9]\+' || true
        fi
      done \
    | sort -Vu
)"

if [[ -n "${glibc_versions}" ]]; then
  echo "Required GLIBC versions:"
  echo "${glibc_versions}"
  max_seen="$(echo "${glibc_versions}" | sed 's/^GLIBC_//' | sort -V | tail -n 1)"
  echo "Max required GLIBC: GLIBC_${max_seen}"

  if ! dpkg --compare-versions "${max_seen}" le "${MAX_GLIBC_VERSION}"; then
    echo "AppImage audit failed: max GLIBC_${max_seen} exceeds allowed GLIBC_${MAX_GLIBC_VERSION}." >&2
    exit 1
  fi
else
  echo "No GLIBC version strings found."
fi

echo "AppImage audit passed (${checked} ELF files checked)."
