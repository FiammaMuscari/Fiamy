#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <bundle-root> [lib-relative-dir]" >&2
  exit 1
fi

BUNDLE_ROOT="$(cd "$1" && pwd)"
LIB_REL="${2:-lib/x86_64-linux-gnu}"
LIB_DIR="${BUNDLE_ROOT}/${LIB_REL}"

if [[ ! -d "${LIB_DIR}" ]]; then
  echo "Runtime library directory not found: ${LIB_DIR}" >&2
  exit 1
fi

is_elf() {
  local file_path="$1"
  [[ -f "${file_path}" ]] || return 1
  file -Lb "${file_path}" 2>/dev/null | grep -q "ELF"
}

# Keep the host's ABI/driver-facing libraries out of the bundle. These are
# either provided by every supported Linux system (glibc/loader) or must match
# the user's graphics/audio/session stack.
should_exclude_library() {
  local base="${1##*/}"

  case "${base}" in
    ld-linux*.so*|linux-vdso.so*|libBrokenLocale.so*|libSegFault.so*)
      return 0
      ;;
    libc.so*|libpthread.so*|libdl.so*|librt.so*|libm.so*|libmvec.so*|libutil.so*|libanl.so*|libresolv.so*|libnss_*.so*|libcrypt.so*|libthread_db.so*)
      return 0
      ;;
    libGL.so*|libEGL.so*|libGLX.so*|libOpenGL.so*|libGLdispatch.so*|libvulkan.so*|libdrm.so*|libgbm.so*|libva.so*|libva-drm.so*|libva-x11.so*|libvdpau.so*|libOpenCL.so*|libcuda.so*|libnvidia-*.so*)
      return 0
      ;;
    libsystemd.so*|libudev.so*)
      return 0
      ;;
  esac

  return 1
}

resolved_dependencies() {
  local elf="$1"
  LD_LIBRARY_PATH="${LIB_DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" ldd "${elf}" 2>/dev/null \
    | awk '
      /version `[^'"'"']+'"'"' not found/ { next }
      /=>[[:space:]]+not found/ { next }
      match($0, /=>[[:space:]]+(\/[^[:space:]]+)/) {
        dep = substr($0, RSTART + 3, RLENGTH - 3)
        sub(/^[[:space:]]+/, "", dep)
        print dep
        next
      }
      /^[[:space:]]*\// {
        print $1
      }
    ' \
    | sort -u
}

copy_runtime_library() {
  local src="$1"
  local dest="${LIB_DIR}/${src##*/}"

  if [[ "${src}" == "${BUNDLE_ROOT}"/* ]]; then
    echo "${src}"
    return
  fi

  if should_exclude_library "${src}"; then
    return
  fi

  if [[ ! -e "${dest}" ]]; then
    cp -aL "${src}" "${dest}"
    chmod u+w "${dest}" 2>/dev/null || true
    echo "Bundled runtime library: ${src##*/}" >&2
  fi

  echo "${dest}"
}

declare -A SEEN_ELF=()
queue=()

while IFS= read -r -d '' candidate; do
  if is_elf "${candidate}"; then
    queue+=("${candidate}")
  fi
done < <(
  find "${BUNDLE_ROOT}/bin" "${LIB_DIR}" -type f -print0 2>/dev/null || true
)

for ((i = 0; i < ${#queue[@]}; i++)); do
  elf="${queue[$i]}"
  [[ -n "${elf}" ]] || continue
  [[ -z "${SEEN_ELF[${elf}]:-}" ]] || continue
  SEEN_ELF["${elf}"]=1

  while IFS= read -r dep; do
    [[ -n "${dep}" && -e "${dep}" ]] || continue
    copied="$(copy_runtime_library "${dep}")"
    if [[ -n "${copied}" && -f "${copied}" && -z "${SEEN_ELF[${copied}]:-}" ]] && is_elf "${copied}"; then
      queue+=("${copied}")
    fi
  done < <(resolved_dependencies "${elf}")
done

if command -v patchelf >/dev/null 2>&1; then
  while IFS= read -r -d '' elf; do
    if ! is_elf "${elf}"; then
      continue
    fi

    elf_dir="$(dirname "${elf}")"
    lib_rel_from_elf="$(realpath --relative-to="${elf_dir}" "${LIB_DIR}")"
    if [[ "${lib_rel_from_elf}" == "." ]]; then
      rpath='$ORIGIN'
    else
      rpath="\$ORIGIN/${lib_rel_from_elf}:\$ORIGIN"
    fi

    patchelf --set-rpath "${rpath}" "${elf}" 2>/dev/null || \
      echo "Warning: could not set RUNPATH on ${elf}" >&2
  done < <(
    find "${BUNDLE_ROOT}/bin" "${LIB_DIR}" -type f -print0 2>/dev/null || true
  )
else
  echo "Warning: patchelf not found; ELF RUNPATHs were not normalized." >&2
fi

echo "Runtime deployment completed for ${BUNDLE_ROOT}"
