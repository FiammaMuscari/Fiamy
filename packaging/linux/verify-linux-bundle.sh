#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <bundle-root> [lib-relative-dir]" >&2
  exit 1
fi

BUNDLE_ROOT="$(cd "$1" && pwd)"
LIB_REL="${2:-lib/x86_64-linux-gnu}"
LIB_DIR="${BUNDLE_ROOT}/${LIB_REL}"
ROOT_LIB_DIR="${BUNDLE_ROOT}/lib"

if [[ ! -d "${LIB_DIR}" ]]; then
  echo "Runtime library directory not found: ${LIB_DIR}" >&2
  exit 1
fi

is_elf() {
  local file_path="$1"
  [[ -f "${file_path}" ]] || return 1
  file -Lb "${file_path}" 2>/dev/null | grep -q "ELF"
}

is_allowed_host_library() {
  local base="${1##*/}"

  case "${base}" in
    ld-linux*.so*|linux-vdso.so*|libBrokenLocale.so*|libSegFault.so*)
      return 0
      ;;
    libc.so*|libpthread.so*|libdl.so*|librt.so*|libm.so*|libmvec.so*|libutil.so*|libanl.so*|libresolv.so*|libnss_*.so*|libcrypt.so*|libthread_db.so*)
      return 0
      ;;
    libvulkan.so*|libva.so*|libva-drm.so*|libva-x11.so*|libvdpau.so*|libOpenCL.so*|libcuda.so*|libnvidia-*.so*)
      return 0
      ;;
    libsystemd.so*|libudev.so*)
      return 0
      ;;
  esac

  return 1
}

is_forbidden_bundled_library() {
  local base="${1##*/}"

  case "${base}" in
    ld-linux*.so*|libBrokenLocale.so*|libSegFault.so*)
      return 0
      ;;
    libc.so*|libpthread.so*|libdl.so*|librt.so*|libm.so*|libmvec.so*|libutil.so*|libanl.so*|libresolv.so*|libnss_*.so*|libcrypt.so*|libthread_db.so*)
      return 0
      ;;
  esac

  return 1
}

is_must_bundle_library() {
  local base="${1##*/}"

  case "${base}" in
    libQt6*.so*|libicu*.so*|libav*.so*|libswresample.so*|libswscale.so*|libpostproc.so*|\
    libapparmor.so*|libdbus-1.so*|libcap.so*|libmount.so*|libblkid.so*|libselinux.so*|\
    libGL.so*|libEGL.so*|libGLX.so*|libOpenGL.so*|libGLdispatch.so*|libdrm.so*|libgbm.so*)
      return 0
      ;;
  esac

  return 1
}

failures=0
checked=0

while IFS= read -r -d '' bundled_file; do
  if is_forbidden_bundled_library "${bundled_file}"; then
    echo "Forbidden glibc/loader component bundled: $(realpath --relative-to="${BUNDLE_ROOT}" "${bundled_file}")" >&2
    failures=$((failures + 1))
  fi
done < <(
  find "${BUNDLE_ROOT}" \( -type f -o -type l \) -print0 2>/dev/null || true
)

while IFS= read -r -d '' elf; do
  is_elf "${elf}" || continue
  checked=$((checked + 1))

  while IFS= read -r line; do
    if [[ "${line}" == *"=> not found"* ]]; then
      echo "Missing dependency in $(realpath --relative-to="${BUNDLE_ROOT}" "${elf}"): ${line}" >&2
      failures=$((failures + 1))
      continue
    fi

    if [[ "${line}" == *"version \`"*' not found'* ]] || [[ "${line}" == *"cannot open shared object file"* ]]; then
      echo "Dependency resolution error in $(realpath --relative-to="${BUNDLE_ROOT}" "${elf}"): ${line}" >&2
      failures=$((failures + 1))
      continue
    fi

    dep=""
    if [[ "${line}" =~ =\>\ (/[^[:space:]]+) ]]; then
      dep="${BASH_REMATCH[1]}"
    elif [[ "${line}" =~ ^[[:space:]]*(/[^[:space:]]+) ]]; then
      dep="${BASH_REMATCH[1]}"
    fi

    [[ -n "${dep}" ]] || continue

    if is_must_bundle_library "${dep}" && [[ "${dep}" != "${BUNDLE_ROOT}/"* ]]; then
      echo "Dependency should be bundled but resolves to host: $(basename "${dep}") for $(realpath --relative-to="${BUNDLE_ROOT}" "${elf}")" >&2
      failures=$((failures + 1))
    elif ! is_allowed_host_library "${dep}" && [[ "${dep}" != "${BUNDLE_ROOT}/"* ]]; then
      # This is intentionally a warning: some desktops provide optional service
      # libraries through plugins. Hard failures are reserved for Qt/ICU/FFmpeg
      # and unresolved libraries.
      echo "Warning: host dependency remains: ${dep##*/} for ${elf#"${BUNDLE_ROOT}/"}" >&2
    fi
  done < <(LD_LIBRARY_PATH="${ROOT_LIB_DIR}:${LIB_DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" ldd "${elf}" 2>&1 || true)
done < <(
  find "${BUNDLE_ROOT}/bin" "${ROOT_LIB_DIR}" "${LIB_DIR}" -type f -print0 2>/dev/null || true
)

if [[ "${checked}" -eq 0 ]]; then
  echo "No ELF files found in ${BUNDLE_ROOT}" >&2
  exit 1
fi

if [[ "${failures}" -ne 0 ]]; then
  echo "Bundle verification failed with ${failures} issue(s)." >&2
  exit 1
fi

echo "Bundle verification passed (${checked} ELF files checked)."
