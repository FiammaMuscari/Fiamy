# Fiamy v1.0.2 Linux beta packaging refresh

This refresh fixes Linux packaging portability issues reported on Arch-based distros such as CachyOS.

## Which asset should I download?

| Your distro | Recommended download |
|---|---|
| Arch / CachyOS / Manjaro / EndeavourOS | `Fiamy-1.0.2-x86_64.AppImage` |
| Fedora / openSUSE / Gentoo / NixOS / other Linux | `Fiamy-1.0.2-x86_64.AppImage` |
| Debian / Ubuntu / Linux Mint / Pop!_OS / Zorin | `fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb` |
| Any Linux distro if the above fails | `fiamy-1.0.2-linux-portable-x86_64.tar.gz` |

## Important notes

- Checksums are available in `linux-sha256sums.txt`.

- Do **not** install the `.deb` on Arch/CachyOS/Manjaro. Use the AppImage or portable tarball.
- The AppImage and portable tarball now bundle Qt, ICU, Qt Multimedia, Wayland/XCB plugins, QML modules, and FFmpeg-related runtime libraries.
- The Debian/Ubuntu package installs Fiamy under `/opt/fiamy` with a private bundled runtime.
- Wayland is tried first and XCB is used as fallback (`QT_QPA_PLATFORM=wayland;xcb`). This is not a Wayland-only build.

## Run commands

AppImage:

```bash
chmod +x Fiamy-1.0.2-x86_64.AppImage
./Fiamy-1.0.2-x86_64.AppImage
```

If FUSE is unavailable:

```bash
./Fiamy-1.0.2-x86_64.AppImage --appimage-extract-and-run
```

Debian/Ubuntu:

```bash
sudo apt install ./fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb
fiamy
```

Portable:

```bash
tar -xzf fiamy-1.0.2-linux-portable-x86_64.tar.gz
./fiamy-linux-portable/Fiamy.sh
```

## Fixed

- Fixed AppImage startup failures caused by missing distro-specific libraries, including `libicui18n.so.76`.
- Added transitive runtime dependency deployment and verification.
- Added smoke tests for portable and AppImage startup.
- Reworked `.deb` packaging so it no longer relies on distro Qt package names.
