# Fiamy Cosmopolitan build

Run this from the repository root:

```sh
./packaging/qt-cosmo/make-fiamy-com.sh
```

The script builds the native Cosmopolitan APE artifact `fiamy.com`. It:

- downloads or reuses `cosmocc` under `dist/tools/cosmocc`
- clones `qtbase`, `qtdeclarative`, and `qtmultimedia` under `dist/qt-cosmo`
- applies the local Qt Cosmopolitan patches from `packaging/qt-cosmo/patches`
- builds a static OpenSSL prefix at `dist/qt-cosmo/openssl-cosmo` so QtNetwork supports HTTPS inside the `.com`
- builds a static Qt prefix at `dist/qt-cosmo/prefix-fat`
- builds a static FFmpeg prefix at `dist/qt-cosmo/ffmpeg-cosmo`
- configures Fiamy with `FIAMY_EMBED_YT_DLP=OFF`; the app downloads the matching `yt-dlp` binary on first YouTube use and caches it in the app data directory
- writes the final executable to `build/fiamy-cosmo-fat/fiamy.com` and copies it to `./fiamy.com`

## Host requirements

Use macOS or Linux/WSL as the build host. Native Windows shells are not supported for building this artifact.

Required tools:

- CMake
- Ninja
- Git
- curl
- unzip
- tar
- make
- perl
- host Qt 6 tools, including QML and shader tools

On macOS with Homebrew, the script auto-detects `/opt/homebrew` or `/usr/local`. On Linux, install the Qt 6 host tools from the distro or Qt installer and set `HOST_QT_PREFIX` if `qtpaths6` is not in `PATH`.

## Runtime expectations

The generated `.com` is intended to run natively on macOS, Linux, and Windows through the `cosmonative` Qt platform path. It should not require installed Qt, FFmpeg, OpenSSL, or `yt-dlp` at runtime. On first YouTube use, it downloads the matching standalone `yt-dlp` binary over Qt's bundled OpenSSL-backed HTTPS path, shows progress in the app UI, and reuses the cached copy afterward. macOS still treats an unsigned downloaded binary as unsigned software, so users may need to allow it through Gatekeeper.

## Useful options

```sh
./packaging/qt-cosmo/make-fiamy-com.sh --app-only
./packaging/qt-cosmo/make-fiamy-com.sh --clean
./packaging/qt-cosmo/make-fiamy-com.sh --no-copy
./packaging/qt-cosmo/make-fiamy-com.sh --reset-qt-sources
```

Use `--reset-qt-sources` when reusing an old `dist/qt-cosmo` checkout from an earlier port attempt. It discards local changes inside the Qt source checkouts before applying the packaged patches.

Useful environment overrides:

```sh
HOST_QT_PREFIX=/opt/homebrew \
JOBS=8 \
./packaging/qt-cosmo/make-fiamy-com.sh
```

The default Qt inputs match the build that was validated during the Cosmopolitan port:

- `QTBASE_REF=refs/changes/12/581112/11`
- `QTDECLARATIVE_REF=v6.10.0-beta1`
- `QTMULTIMEDIA_REF=v6.10.0`

Override those variables only when refreshing the port against newer upstream Qt sources.
