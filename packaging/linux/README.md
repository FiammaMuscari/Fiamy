# Linux packaging

Packaging helpers for Fiamy Linux release assets.

## Output assets

| Script | Output | Intended users |
|---|---|---|
| `package-portable.sh` | `dist/linux-portable/fiamy-<version>-linux-portable-x86_64.tar.gz` | Universal Linux fallback |
| `package-appimage.sh` | `dist/linux-appimage/Fiamy-<version>-x86_64.AppImage` | Arch/CachyOS and most non-Debian distros |
| `package-deb.sh` | `dist/linux-deb/fiamy_<version>_ubuntu-debian-bundled_amd64.deb` | Debian/Ubuntu-family distros |

## Recommended release matrix

- Arch, CachyOS, Manjaro, EndeavourOS: **AppImage first**, portable tarball as fallback. Do not use the `.deb`.
- Fedora, openSUSE, Gentoo, NixOS, unknown distros: **AppImage first**, portable tarball as fallback.
- Debian, Ubuntu, Linux Mint, Pop!_OS, Zorin: **bundled `.deb` first**, AppImage or portable tarball as fallback.

## What was fixed

The old AppImage could start on the build machine but fail on another distro with errors such as:

```text
error while loading shared libraries: libicui18n.so.76: cannot open shared object file
```

The portable/AppImage flow now deploys and verifies transitive runtime libraries from the executable, Qt plugins, and QML modules. This includes ICU, Qt Multimedia, FFmpeg-related libraries, Wayland/XCB platform support, and QML dependencies.

The `.deb` package now installs a private runtime under `/opt/fiamy` instead of depending on distro-specific Qt package names.

## Build

```bash
./packaging/linux/package-portable.sh
FIAMY_SKIP_PORTABLE_BUILD=1 ./packaging/linux/package-appimage.sh
FIAMY_SKIP_PORTABLE_BUILD=1 ./packaging/linux/package-deb.sh ubuntu-debian-bundled
```

You can also run each script independently; without `FIAMY_SKIP_PORTABLE_BUILD=1`, AppImage and `.deb` rebuild the portable bundle first.

## Verify

```bash
./packaging/linux/verify-linux-bundle.sh dist/fiamy-linux-portable
./packaging/linux/smoke-test-linux-bundle.sh dist/fiamy-linux-portable
./packaging/linux/smoke-test-linux-bundle.sh dist/linux-appimage/Fiamy-1.0.2-x86_64.AppImage
```

For the `.deb`, extract and smoke-test the private runtime:

```bash
rm -rf /tmp/fiamy-debtest
mkdir -p /tmp/fiamy-debtest
dpkg-deb -x dist/linux-deb/fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb /tmp/fiamy-debtest
./packaging/linux/smoke-test-linux-bundle.sh /tmp/fiamy-debtest/opt/fiamy
```

## AppImage in environments without FUSE

`appimagetool` itself is an AppImage. In containers or CI environments without FUSE, `package-appimage.sh` retries with `APPIMAGE_EXTRACT_AND_RUN=1` and can reuse an extracted runtime file from `dist/tools/runtime-x86_64`.

## Checksums

```bash
sha256sum dist/linux-appimage/Fiamy-*-x86_64.AppImage \
  dist/linux-portable/fiamy-*-linux-portable-x86_64.tar.gz \
  dist/linux-deb/fiamy_*_ubuntu-debian-bundled_amd64.deb \
  > dist/linux-sha256sums.txt
```

## Upload release assets

```bash
./packaging/linux/upload-release-assets.sh v1.0.2-linux-beta
```

The upload script uses exact current asset names and `--clobber`, so stale `.deb` files in `dist/linux-deb/` are not uploaded accidentally.
