#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_DIR="$ROOT_DIR/packaging/qt-cosmo"
TOOLCHAIN_FILE="$PKG_DIR/cosmo-fat.cmake"

COSMOCC_ROOT="${COSMOCC_ROOT:-$ROOT_DIR/dist/tools/cosmocc}"
COSMOCC_URL="${COSMOCC_URL:-https://cosmo.zip/pub/cosmocc/cosmocc.zip}"
QT_WORK_DIR="${QT_WORK_DIR:-$ROOT_DIR/dist/qt-cosmo}"
SRC_CACHE_DIR="${SRC_CACHE_DIR:-$ROOT_DIR/dist/src}"
QT_PREFIX="${QT_PREFIX:-$QT_WORK_DIR/prefix-fat}"
FFMPEG_VERSION="${FFMPEG_VERSION:-8.0.1}"
FFMPEG_PREFIX="${FFMPEG_PREFIX:-$QT_WORK_DIR/ffmpeg-cosmo}"
OPENSSL_VERSION="${OPENSSL_VERSION:-3.3.2}"
OPENSSL_PREFIX="${OPENSSL_PREFIX:-$QT_WORK_DIR/openssl-cosmo}"

QTBASE_URL="${QTBASE_URL:-https://codereview.qt-project.org/qt/qtbase}"
QTDECLARATIVE_URL="${QTDECLARATIVE_URL:-https://codereview.qt-project.org/qt/qtdeclarative}"
QTMULTIMEDIA_URL="${QTMULTIMEDIA_URL:-https://codereview.qt-project.org/qt/qtmultimedia}"

QTBASE_REF="${QTBASE_REF:-refs/changes/12/581112/11}"
QTDECLARATIVE_REF="${QTDECLARATIVE_REF:-v6.10.0-beta1}"
QTMULTIMEDIA_REF="${QTMULTIMEDIA_REF:-v6.10.0}"

QTBASE_SRC="$QT_WORK_DIR/qtbase"
QTDECLARATIVE_SRC="$QT_WORK_DIR/qtdeclarative"
QTMULTIMEDIA_SRC="$QT_WORK_DIR/qtmultimedia"
FFMPEG_SRC="$SRC_CACHE_DIR/ffmpeg-$FFMPEG_VERSION"
OPENSSL_SRC="$SRC_CACHE_DIR/openssl-$OPENSSL_VERSION"

QTBASE_BUILD="${QTBASE_BUILD:-$ROOT_DIR/build/qtbase-cosmo-fat}"
QTDECLARATIVE_BUILD="${QTDECLARATIVE_BUILD:-$ROOT_DIR/build/qtdeclarative-cosmo-fat}"
QTMULTIMEDIA_BUILD="${QTMULTIMEDIA_BUILD:-$ROOT_DIR/build/qtmultimedia-cosmo-fat}"
APP_BUILD="${APP_BUILD:-$ROOT_DIR/build/fiamy-cosmo-fat}"

RUN_TOOLCHAIN=1
RUN_QT=1
RUN_FFMPEG=1
RUN_OPENSSL=1
RUN_APP=1
COPY_TO_ROOT=1
CLEAN=0
RESET_QT_SOURCES="${RESET_QT_SOURCES:-0}"

usage() {
    cat <<'USAGE'
Usage: packaging/qt-cosmo/make-fiamy-com.sh [options]

Builds the native Cosmopolitan APE fiamy.com:
  1. installs or reuses cosmocc
  2. clones the required Qt modules
  3. applies the Fiamy Qt Cosmopolitan patches
  4. builds static Qt + FFmpeg for Cosmopolitan
  5. builds OpenSSL-backed Qt HTTPS support for first-use yt-dlp download
  6. builds Fiamy with first-use yt-dlp download for macOS, Linux, and Windows

Options:
  --skip-toolchain   Reuse an existing COSMOCC_ROOT.
  --skip-qt          Do not build qtbase, qtdeclarative, or qtmultimedia.
  --skip-ffmpeg      Do not build the FFmpeg prefix.
  --skip-openssl     Do not build the OpenSSL prefix.
  --skip-app         Do not build Fiamy.
  --app-only         Only configure and build Fiamy against existing prefixes.
  --no-copy          Leave the artifact only in the app build directory.
  --clean            Remove generated build directories and install prefixes first.
  --reset-qt-sources Reset Qt source checkouts before applying patches.
  -h, --help         Show this help.

Useful environment overrides:
  COSMOCC_ROOT       Defaults to dist/tools/cosmocc.
  COSMOCC_URL        Defaults to https://cosmo.zip/pub/cosmocc/cosmocc.zip.
  COSMOCC_ARCHIVE    Use a local cosmocc zip instead of downloading.
  HOST_QT_PREFIX     Host Qt prefix used for Qt build tools.
  QTBASE_REF         Defaults to refs/changes/12/581112/11.
  QTDECLARATIVE_REF  Defaults to v6.10.0-beta1.
  QTMULTIMEDIA_REF   Defaults to v6.10.0.
  QT_PREFIX          Defaults to dist/qt-cosmo/prefix-fat.
  FFMPEG_PREFIX      Defaults to dist/qt-cosmo/ffmpeg-cosmo.
  OPENSSL_PREFIX     Defaults to dist/qt-cosmo/openssl-cosmo.
  JOBS               Parallel build jobs.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-toolchain)
            RUN_TOOLCHAIN=0
            ;;
        --skip-qt)
            RUN_QT=0
            ;;
        --skip-ffmpeg)
            RUN_FFMPEG=0
            ;;
        --skip-openssl)
            RUN_OPENSSL=0
            ;;
        --skip-app)
            RUN_APP=0
            ;;
        --app-only)
            RUN_TOOLCHAIN=0
            RUN_QT=0
            RUN_FFMPEG=0
            RUN_OPENSSL=0
            RUN_APP=1
            ;;
        --no-copy)
            COPY_TO_ROOT=0
            ;;
        --clean)
            CLEAN=1
            ;;
        --reset-qt-sources)
            RESET_QT_SOURCES=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
    shift
done

log() {
    printf '\n==> %s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

install_qt_module() {
    local build_dir="$1"

    cmake --install "$build_dir"
    "$PKG_DIR/copy-fat-sidecars.sh" "$build_dir" "$QT_PREFIX"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

detect_jobs() {
    if [[ -n "${JOBS:-}" ]]; then
        printf '%s\n' "$JOBS"
    elif command -v nproc >/dev/null 2>&1; then
        nproc
    elif command -v sysctl >/dev/null 2>&1; then
        sysctl -n hw.logicalcpu 2>/dev/null || printf '4\n'
    else
        printf '4\n'
    fi
}

download_file() {
    local url="$1"
    local dest="$2"

    if [[ -s "$dest" ]]; then
        return
    fi

    mkdir -p "$(dirname "$dest")"
    local tmp="$dest.tmp"
    rm -f "$tmp"
    log "Downloading $url"
    curl -fL --retry 3 --retry-delay 2 -o "$tmp" "$url"
    mv "$tmp" "$dest"
}

detect_host_qt_prefix() {
    if [[ -n "${HOST_QT_PREFIX:-}" ]]; then
        printf '%s\n' "$HOST_QT_PREFIX"
        return
    fi

    if [[ -x /opt/homebrew/bin/qtpaths6 ]]; then
        printf '/opt/homebrew\n'
        return
    fi

    if [[ -x /usr/local/bin/qtpaths6 ]]; then
        printf '/usr/local\n'
        return
    fi

    if command -v qtpaths6 >/dev/null 2>&1; then
        local prefix
        prefix="$(qtpaths6 --query QT_INSTALL_PREFIX 2>/dev/null || true)"
        if [[ -z "$prefix" ]]; then
            prefix="$(qtpaths6 -query QT_INSTALL_PREFIX 2>/dev/null || true)"
        fi
        if [[ -z "$prefix" ]]; then
            prefix="$(qtpaths6 --install-prefix 2>/dev/null || true)"
        fi
        if [[ -n "$prefix" ]]; then
            printf '%s\n' "$prefix"
            return
        fi
    fi

    die "could not find host Qt tools. Install Qt 6 or set HOST_QT_PREFIX."
}

qtpaths_for_prefix() {
    local prefix="$1"
    if [[ -x "$prefix/bin/qtpaths6" ]]; then
        printf '%s/bin/qtpaths6\n' "$prefix"
    elif command -v qtpaths6 >/dev/null 2>&1; then
        command -v qtpaths6
    else
        return 1
    fi
}

ensure_host_supported() {
    local uname_s
    uname_s="$(uname -s)"
    case "$uname_s" in
        Darwin|Linux)
            ;;
        *)
            die "build host '$uname_s' is not supported. Use macOS or Linux/WSL."
            ;;
    esac
}

ensure_prereqs() {
    require_command cmake
    require_command ninja
    require_command git
    require_command curl
    require_command unzip
    require_command tar
    require_command make
    require_command perl
}

ensure_cosmocc() {
    if [[ -x "$COSMOCC_ROOT/bin/cosmocc" && -x "$COSMOCC_ROOT/bin/cosmoc++" ]]; then
        log "Using cosmocc at $COSMOCC_ROOT"
        return
    fi

    if [[ "$RUN_TOOLCHAIN" -eq 0 ]]; then
        die "COSMOCC_ROOT does not contain cosmocc: $COSMOCC_ROOT"
    fi

    local archive="${COSMOCC_ARCHIVE:-$ROOT_DIR/dist/tools/cosmocc.zip}"
    if [[ -z "${COSMOCC_ARCHIVE:-}" ]]; then
        download_file "$COSMOCC_URL" "$archive"
    elif [[ ! -s "$archive" ]]; then
        die "COSMOCC_ARCHIVE does not exist: $archive"
    fi

    local extract_dir="$ROOT_DIR/build/cosmocc-extract"
    rm -rf "$extract_dir"
    mkdir -p "$extract_dir"
    log "Extracting cosmocc"
    unzip -q "$archive" -d "$extract_dir"

    local cosmocc_bin
    cosmocc_bin="$(find "$extract_dir" -path '*/bin/cosmocc' -type f | head -n 1)"
    if [[ -z "$cosmocc_bin" ]]; then
        die "could not find bin/cosmocc inside $archive"
    fi

    local unpacked_root
    unpacked_root="$(cd "$(dirname "$cosmocc_bin")/.." && pwd)"
    rm -rf "$COSMOCC_ROOT"
    mkdir -p "$COSMOCC_ROOT"
    cp -R "$unpacked_root"/. "$COSMOCC_ROOT"/
    chmod -R u+rwX "$COSMOCC_ROOT"
    rm -rf "$extract_dir"

    [[ -x "$COSMOCC_ROOT/bin/cosmocc" ]] || die "cosmocc install failed"
}

ensure_checkout() {
    local name="$1"
    local url="$2"
    local ref="$3"
    local dir="$4"

    if [[ -e "$dir" && ! -d "$dir/.git" ]]; then
        die "$dir exists but is not a git checkout"
    fi

    if [[ ! -d "$dir/.git" ]]; then
        log "Cloning $name"
        mkdir -p "$(dirname "$dir")"
        git clone --filter=blob:none "$url" "$dir"
    fi

    if [[ "$RESET_QT_SOURCES" -eq 1 ]]; then
        log "Resetting $name source checkout"
        git -C "$dir" reset --hard
        git -C "$dir" clean -fd
    fi

    if git -C "$dir" diff --quiet && git -C "$dir" diff --cached --quiet; then
        log "Checking out $name at $ref"
        git -C "$dir" fetch --tags origin "$ref" || git -C "$dir" fetch --tags origin
        if git -C "$dir" rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
            git -C "$dir" checkout "$ref"
        else
            git -C "$dir" checkout FETCH_HEAD
        fi
    else
        log "Using existing $name checkout with local changes"
    fi
}

apply_patch_once() {
    local name="$1"
    local dir="$2"
    local patch="$3"

    if git -C "$dir" apply --check "$patch"; then
        log "Applying $name patch"
        git -C "$dir" apply "$patch"
    elif git -C "$dir" apply -R --check "$patch"; then
        log "$name patch is already applied"
    else
        die "could not apply $patch to $dir"
    fi
}

apply_source_patch_once() {
    local name="$1"
    local dir="$2"
    local patch="$3"

    if git -C "$dir" apply -R --check "$patch"; then
        log "$name patch is already applied"
    elif git -C "$dir" apply --check "$patch"; then
        log "Applying $name patch"
        git -C "$dir" apply "$patch"
    else
        die "could not apply $patch to $dir"
    fi
}

prepare_qt_sources() {
    ensure_checkout qtbase "$QTBASE_URL" "$QTBASE_REF" "$QTBASE_SRC"
    ensure_checkout qtdeclarative "$QTDECLARATIVE_URL" "$QTDECLARATIVE_REF" "$QTDECLARATIVE_SRC"
    ensure_checkout qtmultimedia "$QTMULTIMEDIA_URL" "$QTMULTIMEDIA_REF" "$QTMULTIMEDIA_SRC"

    apply_patch_once qtbase "$QTBASE_SRC" "$PKG_DIR/patches/qtbase-cosmo-native-platform.patch"
    apply_patch_once qtdeclarative "$QTDECLARATIVE_SRC" "$PKG_DIR/patches/qtdeclarative-host-tool-backports.patch"
    apply_patch_once qtmultimedia "$QTMULTIMEDIA_SRC" "$PKG_DIR/patches/qtmultimedia-cosmo-fixes.patch"
}

build_qtbase() {
    local prefix_path="$QT_PREFIX;$OPENSSL_PREFIX"

    log "Configuring qtbase"
    cmake -S "$QTBASE_SRC" -B "$QTBASE_BUILD" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
        -DCOSMOCC_ROOT="$COSMOCC_ROOT" \
        -DCMAKE_INSTALL_PREFIX="$QT_PREFIX" \
        -DCMAKE_PREFIX_PATH="$prefix_path" \
        -DOPENSSL_ROOT_DIR="$OPENSSL_PREFIX" \
        -DOPENSSL_USE_STATIC_LIBS=TRUE \
        -DQT_HOST_PATH="$HOST_QT_PREFIX" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_WITH_PCH=OFF \
        -DQT_BUILD_EXAMPLES=OFF \
        -DQT_BUILD_TESTS=OFF \
        -DQT_QPA_DEFAULT_PLATFORM=cosmonative \
        -DQT_QPA_PLATFORMS=cosmonative \
        -DINPUT_opengl=no \
        -DFEATURE_opengl=OFF \
        -DFEATURE_xcb=OFF \
        -DFEATURE_xlib=OFF \
        -DFEATURE_fontconfig=OFF \
        -DFEATURE_dbus=OFF \
        -DFEATURE_icu=OFF \
        -DFEATURE_ssl=ON \
        -DFEATURE_openssl=ON \
        -DFEATURE_openssl_linked=ON \
        -DFEATURE_dtls=OFF \
        -DFEATURE_ocsp=OFF \
        -DFEATURE_getifaddrs=OFF \
        -DFEATURE_reduce_relocations=OFF \
        -DFEATURE_stack_protector=OFF \
        -DFEATURE_stack_clash_protection=OFF

    cmake --build "$QTBASE_BUILD" --parallel "$JOBS"
    install_qt_module "$QTBASE_BUILD"
}

prepare_openssl_source() {
    if [[ -x "$OPENSSL_SRC/Configure" ]]; then
        return
    fi

    local archive="$SRC_CACHE_DIR/openssl-$OPENSSL_VERSION.tar.gz"
    download_file "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" "$archive"
    mkdir -p "$SRC_CACHE_DIR"
    tar -C "$SRC_CACHE_DIR" -xf "$archive"
}

build_openssl() {
    prepare_openssl_source

    log "Configuring OpenSSL $OPENSSL_VERSION"
    rm -rf "$OPENSSL_PREFIX"
    (
        cd "$OPENSSL_SRC"
        make clean >/dev/null 2>&1 || true
        ./Configure linux-x86_64 \
            no-shared \
            no-tests \
            no-asm \
            no-threads \
            no-dso \
            no-module \
            no-engine \
            no-apps \
            --prefix="$OPENSSL_PREFIX" \
            --libdir=lib \
            CC="$COSMOCC_ROOT/bin/cosmocc" \
            CXX="$COSMOCC_ROOT/bin/cosmoc++" \
            AR="$COSMOCC_ROOT/bin/cosmoar" \
            RANLIB="$PKG_DIR/cosmoranlib-fat" \
            CFLAGS="-mcosmo" \
            LDFLAGS="-mcosmo"

        make -j "$JOBS" build_libs
        make install_sw

        local sidecar_dir="$OPENSSL_PREFIX/lib/.aarch64"
        mkdir -p "$sidecar_dir"
        cp .aarch64/libcrypto.a "$sidecar_dir/libcrypto.a"
        cp .aarch64/libssl.a "$sidecar_dir/libssl.a"
    )
}

prepare_ffmpeg_source() {
    if [[ -x "$FFMPEG_SRC/configure" ]]; then
        return
    fi

    local archive="$SRC_CACHE_DIR/ffmpeg-$FFMPEG_VERSION.tar.xz"
    download_file "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz" "$archive"
    mkdir -p "$SRC_CACHE_DIR"
    tar -C "$SRC_CACHE_DIR" -xf "$archive"
}

build_ffmpeg() {
    prepare_ffmpeg_source
    apply_source_patch_once ffmpeg "$FFMPEG_SRC" "$PKG_DIR/patches/ffmpeg-cosmo-tx-pfa-guard.patch"

    log "Configuring FFmpeg $FFMPEG_VERSION"
    mkdir -p "$FFMPEG_PREFIX"
    (
        cd "$FFMPEG_SRC"
        ./configure \
            --prefix="$FFMPEG_PREFIX" \
            --enable-cross-compile \
            --target-os=linux \
            --arch=x86_64 \
            --cc="$COSMOCC_ROOT/bin/cosmocc" \
            --cxx="$COSMOCC_ROOT/bin/cosmoc++" \
            --ar="$COSMOCC_ROOT/bin/cosmoar" \
            --ranlib="$PKG_DIR/cosmoranlib-fat" \
            --strip="$COSMOCC_ROOT/bin/cosmocross" \
            --extra-cflags=-mcosmo \
            --extra-ldflags=-mcosmo \
            --disable-shared \
            --enable-static \
            --disable-programs \
            --disable-doc \
            --disable-debug \
            --disable-network \
            --disable-autodetect \
            --disable-iconv \
            --disable-bzlib \
            --disable-lzma \
            --disable-zlib \
            --disable-xlib \
            --disable-sdl2 \
            --disable-securetransport \
            --disable-audiotoolbox \
            --disable-videotoolbox \
            --disable-vaapi \
            --disable-vdpau \
            --disable-asm \
            --disable-inline-asm \
            --disable-x86asm \
            --disable-runtime-cpudetect \
            --disable-everything \
            --enable-avcodec \
            --enable-avformat \
            --enable-avutil \
            --enable-swresample \
            --enable-swscale \
            --enable-protocol=file \
            --enable-demuxer=mp3,mov,wav,flac,ogg,matroska \
            --enable-decoder=mp3,mp3float,aac,aac_fixed,flac,vorbis,opus,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le \
            --enable-parser=aac,aac_latm,flac,mpegaudio,opus,vorbis

        make -j "$JOBS"
        make install

        local sidecar_dir="$FFMPEG_PREFIX/lib/.aarch64"
        mkdir -p "$sidecar_dir"
        find . -path '*/.aarch64/lib*.a' -type f | while IFS= read -r sidecar_archive; do
            cp "$sidecar_archive" "$sidecar_dir/$(basename "$sidecar_archive")"
        done
    )
}

build_qtdeclarative() {
    log "Configuring qtdeclarative"
    cmake -S "$QTDECLARATIVE_SRC" -B "$QTDECLARATIVE_BUILD" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
        -DCOSMOCC_ROOT="$COSMOCC_ROOT" \
        -DCMAKE_INSTALL_PREFIX="$QT_PREFIX" \
        -DCMAKE_PREFIX_PATH="$QT_PREFIX" \
        -DQT_HOST_PATH="$HOST_QT_PREFIX" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_WITH_PCH=OFF \
        -DQT_BUILD_EXAMPLES=OFF \
        -DQT_BUILD_TESTS=OFF \
        -DQT_QPA_DEFAULT_PLATFORM=cosmonative \
        -DQT_QPA_PLATFORMS=cosmonative \
        -DFEATURE_qml_jit=OFF \
        -DQT_FEATURE_qml_jit=OFF \
        -DQT_QML_NO_CACHEGEN=ON

    cmake --build "$QTDECLARATIVE_BUILD" --parallel "$JOBS"
    install_qt_module "$QTDECLARATIVE_BUILD"
}

build_qtmultimedia() {
    local prefix_path="$QT_PREFIX;$FFMPEG_PREFIX;$HOST_QT_PREFIX"

    log "Configuring qtmultimedia"
    cmake -S "$QTMULTIMEDIA_SRC" -B "$QTMULTIMEDIA_BUILD" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
        -DCOSMOCC_ROOT="$COSMOCC_ROOT" \
        -DCMAKE_INSTALL_PREFIX="$QT_PREFIX" \
        -DCMAKE_PREFIX_PATH="$prefix_path" \
        -DQT_HOST_PATH="$HOST_QT_PREFIX" \
        -DFFMPEG_DIR="$FFMPEG_PREFIX" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_WITH_PCH=OFF \
        -DQT_BUILD_EXAMPLES=OFF \
        -DQT_BUILD_TESTS=OFF \
        -DQT_QPA_DEFAULT_PLATFORM=cosmonative \
        -DQT_QPA_PLATFORMS=cosmonative \
        -DQT_QML_NO_CACHEGEN=ON \
        -DFEATURE_ffmpeg=ON \
        -DQT_FEATURE_ffmpeg=ON \
        -DFEATURE_gstreamer=OFF \
        -DQT_FEATURE_gstreamer=OFF \
        -DFEATURE_alsa=OFF \
        -DQT_FEATURE_alsa=OFF \
        -DFEATURE_pulseaudio=OFF \
        -DQT_FEATURE_pulseaudio=OFF \
        -DFEATURE_pipewire=OFF \
        -DQT_FEATURE_pipewire=OFF

    cmake --build "$QTMULTIMEDIA_BUILD" --parallel "$JOBS"
    install_qt_module "$QTMULTIMEDIA_BUILD"
}

build_app() {
    local prefix_path="$QT_PREFIX;$FFMPEG_PREFIX;$HOST_QT_PREFIX"

    log "Configuring Fiamy"
    cmake -S "$ROOT_DIR" -B "$APP_BUILD" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
        -DCOSMOCC_ROOT="$COSMOCC_ROOT" \
        -DQT_COSMO_PREFIX="$QT_PREFIX" \
        -DCMAKE_PREFIX_PATH="$prefix_path" \
        -DFIAMY_QT_HOST_PREFIX="$HOST_QT_PREFIX" \
        -DFIAMY_EMBED_YT_DLP=OFF

    cmake --build "$APP_BUILD" --target Fiamy --parallel "$JOBS"

    local artifact="$APP_BUILD/fiamy.com"
    if [[ ! -f "$artifact" ]]; then
        artifact="$(find "$APP_BUILD" -name fiamy.com -type f | head -n 1)"
    fi
    [[ -f "$artifact" ]] || die "Fiamy build completed without fiamy.com"

    if [[ "$COPY_TO_ROOT" -eq 1 ]]; then
        cmake -E copy_if_different "$artifact" "$ROOT_DIR/fiamy.com"
        log "Copied artifact to $ROOT_DIR/fiamy.com"
    else
        log "Artifact: $artifact"
    fi
}

clean_outputs() {
    log "Removing generated build directories and install prefixes"
    rm -rf \
        "$QTBASE_BUILD" \
        "$QTDECLARATIVE_BUILD" \
        "$QTMULTIMEDIA_BUILD" \
        "$APP_BUILD" \
        "$QT_PREFIX" \
        "$FFMPEG_PREFIX" \
        "$OPENSSL_PREFIX"
}

main() {
    ensure_host_supported
    ensure_prereqs

    JOBS="$(detect_jobs)"
    HOST_QT_PREFIX="$(detect_host_qt_prefix)"
    export COSMOCC_ROOT HOST_QT_PREFIX JOBS

    local qtpaths=""
    qtpaths="$(qtpaths_for_prefix "$HOST_QT_PREFIX" || true)"
    local qt_version="unknown"
    if [[ -n "$qtpaths" ]]; then
        qt_version="$("$qtpaths" --qt-version 2>/dev/null || true)"
    fi

    log "Host Qt prefix: $HOST_QT_PREFIX"
    log "Host Qt version: ${qt_version:-unknown}"
    log "Parallel jobs: $JOBS"

    if [[ "$CLEAN" -eq 1 ]]; then
        clean_outputs
    fi

    if [[ "$RUN_TOOLCHAIN" -eq 1 ]]; then
        ensure_cosmocc
    else
        [[ -x "$COSMOCC_ROOT/bin/cosmocc" ]] || die "COSMOCC_ROOT is missing cosmocc: $COSMOCC_ROOT"
    fi

    if [[ "$RUN_QT" -eq 1 ]]; then
        prepare_qt_sources
    fi

    if [[ "$RUN_OPENSSL" -eq 1 ]]; then
        build_openssl
    fi

    if [[ "$RUN_QT" -eq 1 ]]; then
        build_qtbase
    fi

    if [[ "$RUN_FFMPEG" -eq 1 ]]; then
        build_ffmpeg
    fi

    if [[ "$RUN_QT" -eq 1 ]]; then
        build_qtdeclarative
        build_qtmultimedia
    fi

    if [[ "$RUN_APP" -eq 1 ]]; then
        build_app
    fi
}

main "$@"
