# 🎧 Fiamy MP3 YouTube Player

https://github.com/user-attachments/assets/527a1af5-66ef-4c0c-b44b-d12c9d5a331a

A lightweight desktop MP3 player built with **Qt + C++**, focused on streaming audio from **YouTube** in a smooth and modern way.

[![License: MIT](https://img.shields.io/badge/License-Open_Source-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue?style=for-the-badge&logo=linux)](https://github.com/FiammaMuscari/Fiamy/releases)

<div align="center">

<img width="556" height="715" alt="image (21)" src="https://github.com/user-attachments/assets/72b66244-c2a2-4cd0-86d4-d05e65d4cbef" />

<img width="508" height="696" alt="image (22)" src="https://github.com/user-attachments/assets/5358347e-c7af-44fd-8051-f3d145d245c6" />
</div>

## 📦 Download

| Platform / distro family | Recommended asset | Notes |
|---|---|---|
| Windows | `Fiamy_Setup-1.0.1.exe` | Windows build is kept on the `windows-legacy` branch. |
| Arch / CachyOS / Manjaro / EndeavourOS | `Fiamy-1.0.2-x86_64.AppImage` | Do **not** install the `.deb` on Arch-based distros. |
| Fedora / openSUSE / Gentoo / NixOS / other Linux | `Fiamy-1.0.2-x86_64.AppImage` | Use the portable `.tar.gz` if AppImage/FUSE is blocked. |
| Debian / Ubuntu / Linux Mint / Pop!_OS / Zorin | `fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb` | Installs under `/opt/fiamy` with a private bundled Qt runtime. |
| Any Linux fallback | `fiamy-1.0.2-linux-portable-x86_64.tar.gz` | Extract and run `./fiamy-linux-portable/Fiamy.sh`. |

Release page: <https://github.com/FiammaMuscari/Fiamy/releases>

Optional checksum file: `linux-sha256sums.txt`.

### Linux quick start

AppImage:

```bash
chmod +x Fiamy-1.0.2-x86_64.AppImage
./Fiamy-1.0.2-x86_64.AppImage
```

If your distro cannot mount AppImages because FUSE is missing:

```bash
./Fiamy-1.0.2-x86_64.AppImage --appimage-extract-and-run
```

Debian/Ubuntu package:

```bash
sudo apt install ./fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb
```

Portable Linux bundle:

```bash
tar -xzf fiamy-1.0.2-linux-portable-x86_64.tar.gz
./fiamy-linux-portable/Fiamy.sh
```

> Arch/CachyOS users: `pacman -S ./file.deb` is not valid, and `pacman -U` is only for Arch packages (`.pkg.tar.zst`). Use the AppImage or portable archive instead.

## ✨ Features

- 📋 **Paste YouTube links**
  - Right click → paste
  - Or paste the link and press **➕ Add**
- 🎶 **Instant audio streaming from YouTube**
- 📥 **Download full YouTube playlists** while keeping the original order
- 📌 **Mini-player mode** that can be minimized and docked to screen edges
- 🧠 **Smart queue management**
- 🔄 Uses **yt-dlp** with automatic updates configured
- 🎵 **Cached audio** reused between sessions
- 🌈 **Reactive visualizer** tuned for smoother Linux playback
- 🖥️ Built with **Qt 6 / QML + C++**

## 🌿 Branches

- **`main`** → project overview, current release packaging, and shared entry point
- **`linux-qt6`** → Linux Qt 6 work branch and Linux-specific history
- **`windows-legacy`** → preserved Windows installer flow

## 🐧 Linux packaging status

The Linux assets were refreshed to avoid cross-distro runtime failures such as missing ICU/Qt libraries (`libicui18n.so.*`, Qt Multimedia, Wayland/XCB plugins, etc.). The AppImage and portable archive now bundle the Qt runtime and validated transitive libraries. The `.deb` package is Debian/Ubuntu-oriented and installs the same private runtime under `/opt/fiamy`.

Validation helpers:

```bash
./packaging/linux/package-portable.sh
./packaging/linux/package-appimage.sh
./packaging/linux/package-deb.sh ubuntu-debian-bundled
./packaging/linux/smoke-test-linux-bundle.sh dist/fiamy-linux-portable
./packaging/linux/smoke-test-linux-bundle.sh dist/linux-appimage/Fiamy-1.0.2-x86_64.AppImage
```

## 🪟 Windows status

The Windows installer published on GitHub is still available from the historical flow.

For Windows-specific development, use:

```bash
git checkout windows-legacy
```

## 🛠️ Tech Stack

- **Qt 6 (QML + C++)**
- **CMake**
- **yt-dlp**
- **MinGW (Windows)**

## 📚 Extra notes

Linux packaging notes are available in:

- `docs/linux.md`
- `packaging/linux/README.md`
- `platform/linux/README.md`

## 🔗 Releases

- All releases: <https://github.com/FiammaMuscari/Fiamy/releases>
- Linux beta release: <https://github.com/FiammaMuscari/Fiamy/releases/tag/v1.0.2-linux-beta>
