# 🎧 Fiamy MP3 Youtube Player



https://github.com/user-attachments/assets/527a1af5-66ef-4c0c-b44b-d12c9d5a331a



A lightweight desktop MP3 player built with **Qt + C++**, focused on streaming udio from **YouTube** in a smooth and modern way.


[![License: MIT](https://img.shields.io/badge/License-Open_Source-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue?style=for-the-badge&logo=linux)](https://github.com/FiammaMuscari/Fiamy/releases)
<div align="center">

<img width="556" height="715" alt="image (21)" src="https://github.com/user-attachments/assets/72b66244-c2a2-4cd0-86d4-d05e65d4cbef" />

<img width="508" height="696" alt="image (22)" src="https://github.com/user-attachments/assets/5358347e-c7af-44fd-8051-f3d145d245c6" />
</div>

## 📦 Download

<div align="center">

| Windows Installer | Linux Installer |
|---|---|
| **[⬇️ Download Fiamy v1.0.1 (Windows)](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.1/Fiamy_Setup-1.0.1.exe)** | **[⬇️ Download Fiamy v1.0.2 (Linux)](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.2-linux-beta/fiamy_1.0.2_ubuntu-qt6.9_amd64.deb)** |

*Free & Open Source • No ads • No tracking*

</div>

## ✨ Features

- 📋 **Paste YouTube links**
  - Right click → paste
  - Or paste the link and press **➕ Add**
- 🎶 **Instant audio streaming from YouTube**
- 📥 **Download full YouTube playlists** (keeps original order)
- 📌 **Mini-player mode**
  - Can be minimized and docked to screen edges
- 🧠 **Smart queue management**
- 🔄 Uses **yt-dlp** with automatic updates configured
- 🎵 **Cached audio**
  - Streamed songs are temporarily stored in:
    ```text
    cache/audio
    ```
  - Cache is reused between sessions and old entries are cleaned only when needed
- 🌈 **Reactive visualizer**
  - Linux package refreshed with lower CPU usage
  - Smoother / slower visualizer bars on `linux-qt6`
- 🖥️ Built with **Qt (QML) + C++**

## 🌿 Branches

- **`linux-qt6`** → active Linux branch
- **`windows-legacy`** → preserved Windows branch
- **`main`** → project overview / shared entry point

## 🐧 Linux status

The current Linux work lives on **`linux-qt6`**.

Latest Linux packaging refresh:

- reduced visualizer CPU usage
- smoother / slower visualizer bars
- refreshed `.deb` package build
- bundled `yt-dlp` when available during packaging

Install on Ubuntu / Debian based systems with:

```bash
sudo apt install ./fiamy_1.0.2_ubuntu-qt6.9_amd64.deb
```

Or build locally from the Linux branch:

```bash
git checkout linux-qt6
./packaging/linux/build-release.sh
./packaging/linux/package-deb.sh
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

Linux packaging notes available in the repo:

- `docs/linux.md`
- `packaging/linux/README.md`
- `platform/linux/README.md`

## 🔗 Releases

- All releases: <https://github.com/FiammaMuscari/Fiamy/releases>
- Linux beta release: <https://github.com/FiammaMuscari/Fiamy/releases/tag/v1.0.2-linux-beta>
