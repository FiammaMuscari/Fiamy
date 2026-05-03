# Linux installation and packaging

This document describes which Linux asset to use and how the current Linux packages are built.

## Which file should I download?

| Distro family | Best choice | Alternative | Avoid |
|---|---|---|---|
| Arch, CachyOS, Manjaro, EndeavourOS | AppImage | Portable `.tar.gz` | `.deb` |
| Fedora, openSUSE, Gentoo, NixOS, other non-Debian distros | AppImage | Portable `.tar.gz` | `.deb` |
| Debian, Ubuntu, Linux Mint, Pop!_OS, Zorin | Bundled `.deb` | AppImage or portable `.tar.gz` | Arch packages/AUR instructions |

## Assets

- `Fiamy-1.0.2-x86_64.AppImage`
  - Recommended for Arch/CachyOS and most non-Debian distros.
  - Bundles Qt, ICU, Qt Multimedia, Wayland/XCB plugins, QML modules, and FFmpeg-related runtime libraries.
- `fiamy-1.0.2-linux-portable-x86_64.tar.gz`
  - Universal fallback. Extract and run `Fiamy.sh`.
- `fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb`
  - Debian/Ubuntu-family installer. Installs under `/opt/fiamy` with a private Qt runtime.
  - Not an Arch package.
- `linux-sha256sums.txt`
  - SHA-256 checksums for the Linux assets.

## AppImage

```bash
chmod +x Fiamy-1.0.2-x86_64.AppImage
./Fiamy-1.0.2-x86_64.AppImage
```

If FUSE is missing or disabled:

```bash
./Fiamy-1.0.2-x86_64.AppImage --appimage-extract-and-run
```

Common distro-specific FUSE packages:

```bash
# Arch / CachyOS / Manjaro
sudo pacman -S fuse2

# Debian / Ubuntu / Linux Mint
sudo apt install libfuse2 || sudo apt install libfuse2t64
```

The AppImage should no longer fail with missing ICU errors such as:

```text
libicui18n.so.76: cannot open shared object file
```

If that still happens, the AppImage was not rebuilt from the fixed packaging scripts.

## Debian / Ubuntu package

```bash
sudo apt install ./fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb
fiamy
```

The package layout is intentionally private:

```text
/opt/fiamy/          bundled runtime and app
/usr/bin/fiamy      launcher
/usr/share/applications/fiamy.desktop
/usr/share/icons/hicolor/256x256/apps/fiamy.png
```

Do not install this file on Arch-based distros. Arch package managers expect native packages, not `.deb` files.

## Portable tarball

```bash
tar -xzf fiamy-1.0.2-linux-portable-x86_64.tar.gz
./fiamy-linux-portable/Fiamy.sh
```

The portable bundle is useful when:

- AppImage FUSE mounting is blocked.
- The system is not Debian/Ubuntu-based.
- You want to run Fiamy without installing anything system-wide.

## Runtime compatibility notes

The bundle intentionally includes libraries that commonly differ across distros:

- Qt 6 runtime libraries
- Qt QML modules
- Qt platform plugins for Wayland and XCB
- Qt Multimedia and FFmpeg runtime libraries
- ICU (`libicu*.so.*`)

It intentionally does **not** try to replace host GPU/session ABI libraries such as glibc, Mesa/OpenGL/EGL, DBus, systemd, or graphics drivers. Those must come from the user's distro.

Default Qt platform selection is:

```bash
QT_QPA_PLATFORM=wayland;xcb
```

That means Wayland is tried first and XCB is used as a fallback. It is not a hard Wayland-only build.

## Build locally

```bash
./packaging/linux/package-portable.sh
./packaging/linux/package-appimage.sh
./packaging/linux/package-deb.sh ubuntu-debian-bundled
```

## Verify locally

```bash
./packaging/linux/verify-linux-bundle.sh dist/fiamy-linux-portable
./packaging/linux/smoke-test-linux-bundle.sh dist/fiamy-linux-portable
./packaging/linux/smoke-test-linux-bundle.sh dist/linux-appimage/Fiamy-1.0.2-x86_64.AppImage
```

The smoke test runs with `QT_QPA_PLATFORM=offscreen`, so it can catch startup linker/plugin errors without needing a visible desktop session.

## Troubleshooting

### `error while loading shared libraries: libicui18n.so.*`

The asset is stale or incomplete. Download the refreshed AppImage/portable/deb built from the fixed scripts.

### AppImage FUSE error

Install the distro's FUSE 2 package or run:

```bash
./Fiamy-1.0.2-x86_64.AppImage --appimage-extract-and-run
```

### Arch/CachyOS and `.deb`

Do not use `.deb` on Arch-based distros. Use AppImage or the portable archive.
