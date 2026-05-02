# 🎧 Fiamy Windows legacy branch

This branch preserves the historical Windows flow for Fiamy, an MP3/YouTube player built with **Qt + QML + C++**.

For current Linux packaging and cross-distro downloads, use the `main` branch and the Linux release assets.

## Windows download

**[Download Fiamy v1.0.1 for Windows](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.1/Fiamy_Setup-1.0.1.exe)**

Release page: <https://github.com/FiammaMuscari/Fiamy/releases>

## Linux downloads are not built from this branch

| Distro family | Recommended Linux asset |
|---|---|
| Arch / CachyOS / Manjaro / EndeavourOS | `Fiamy-1.0.2-x86_64.AppImage` |
| Fedora / openSUSE / Gentoo / NixOS / other Linux | `Fiamy-1.0.2-x86_64.AppImage` |
| Debian / Ubuntu / Linux Mint / Pop!_OS / Zorin | `fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb` |
| Any Linux fallback | `fiamy-1.0.2-linux-portable-x86_64.tar.gz` |

Do **not** use the `.deb` on Arch/CachyOS/Manjaro. Use the AppImage or portable tarball instead.

Linux release page: <https://github.com/FiammaMuscari/Fiamy/releases/tag/v1.0.2-linux-beta>

## Features

- Paste YouTube links
- Stream audio from YouTube
- Download full playlists while keeping order
- Mini-player mode
- Smart queue management
- `yt-dlp` integration
- Cached audio
- Qt/QML interface

## Run locally on Windows

### Qt Creator

1. Open **Qt Creator**.
2. Select **File → Open File or Project**.
3. Open `CMakeLists.txt`.
4. Choose a **Desktop Qt 6.x MinGW 64-bit** kit.
5. Configure and run.

## Branches

- `main` — project overview and current release packaging
- `linux-qt6` — Linux Qt 6 work branch
- `windows-legacy` — this preserved Windows branch
