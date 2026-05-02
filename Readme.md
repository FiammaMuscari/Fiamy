# 🎧 Fiamy Linux Qt 6 branch

Fiamy is an MP3/YouTube player built with **Qt 6 + QML + C++**.

This branch keeps the Linux Qt 6 history and Linux-specific implementation work. Current release packaging is documented on `main` and in the release notes, but the recommended Linux asset matrix is the same.

## Recommended Linux downloads

| Distro family | Recommended asset | Alternative | Do not use |
|---|---|---|---|
| Arch / CachyOS / Manjaro / EndeavourOS | `Fiamy-1.0.2-x86_64.AppImage` | `fiamy-1.0.2-linux-portable-x86_64.tar.gz` | `.deb` |
| Fedora / openSUSE / Gentoo / NixOS / other Linux | `Fiamy-1.0.2-x86_64.AppImage` | `fiamy-1.0.2-linux-portable-x86_64.tar.gz` | `.deb` |
| Debian / Ubuntu / Linux Mint / Pop!_OS / Zorin | `fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb` | AppImage or portable tarball | Arch/AUR packages |

Release page: <https://github.com/FiammaMuscari/Fiamy/releases/tag/v1.0.2-linux-beta>

## Linux quick start

AppImage:

```bash
chmod +x Fiamy-1.0.2-x86_64.AppImage
./Fiamy-1.0.2-x86_64.AppImage
```

If FUSE is unavailable:

```bash
./Fiamy-1.0.2-x86_64.AppImage --appimage-extract-and-run
```

Debian/Ubuntu package:

```bash
sudo apt install ./fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb
fiamy
```

Portable fallback:

```bash
tar -xzf fiamy-1.0.2-linux-portable-x86_64.tar.gz
./fiamy-linux-portable/Fiamy.sh
```

## Packaging refresh

The refreshed Linux packaging fixes cross-distro runtime errors such as:

```text
libicui18n.so.76: cannot open shared object file
```

The AppImage and portable archive bundle Qt, ICU, Qt Multimedia, FFmpeg-related runtime libraries, QML modules, and Wayland/XCB platform plugins. The `.deb` package is only for Debian/Ubuntu-family distros and installs a private runtime under `/opt/fiamy`.

## Current Linux status

- ✅ Local playback
- ✅ YouTube integration with `yt-dlp`
- ✅ Local cache
- ✅ Linux-adapted visualizer
- ✅ Smoother visualizer tuned for large playlists
- ✅ File picker
- ✅ AppImage, portable tarball, and Debian/Ubuntu `.deb` packaging

## Development

```bash
cmake -S . -B build-linux
cmake --build build-linux -j4
./build-linux/fiamy
```

## Branches

- `main` — project overview and current release packaging
- `linux-qt6` — Linux Qt 6 work branch
- `windows-legacy` — preserved Windows flow
