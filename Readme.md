# 🎧 Fiamy

Fiamy is an MP3/YouTube player built with **Qt 6 + QML + C++**.  
This repository is organized to clearly separate the **Windows** and **Linux** flows without duplicating the whole project 💿

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-Open_Source-green?style=for-the-badge)](LICENSE)
[![Linux](https://img.shields.io/badge/Linux-Qt6-2ea043?style=for-the-badge&logo=linux)](https://github.com/FiammaMuscari/Fiamy/tree/linux-qt6)
[![Windows](https://img.shields.io/badge/Windows-Legacy-0078d4?style=for-the-badge&logo=windows)](https://github.com/FiammaMuscari/Fiamy/tree/windows-legacy)

</div>

## 🌿 Project branches

- **`linux-qt6`** → active Linux / Qt6 branch
- **`windows-legacy`** → preserved Windows flow
- **`main`** → general reference branch

> If you are working on Linux, use **`linux-qt6`**.  
> If you need the historical Windows behavior, use **`windows-legacy`**.

## ✨ What Fiamy does

- 🎵 Plays local audio files
- 🔗 Adds songs from YouTube links
- 📋 Queues full playlists for download
- 📦 Temporarily caches audio
- 📌 Includes a mini-player
- 🌈 Includes a reactive visualizer

## 📁 Repository layout

```text
.
├── components/          # shared QML UI
├── thirdparty/          # embedded dependencies
├── docs/                # platform notes
├── platform/
│   ├── linux/           # Linux-specific notes and assets
│   └── windows/         # Windows-specific notes and assets
├── packaging/
│   ├── linux/           # future Linux packaging
│   └── windows/         # future Windows packaging
├── CMakeLists.txt
├── Main.qml
└── *.cpp / *.h
```

## 🐧 Linux (branch `linux-qt6`)

### Current status

- ✅ local playback
- ✅ YouTube integration with `yt-dlp`
- ✅ local cache
- ✅ Linux-adapted visualizer
- ✅ smoother visualizer tuned for large playlist installs
- ✅ working file picker
- ✅ `.deb` installer available via `packaging/linux/package-deb.sh`

### Audio cache

While Fiamy is running on Linux, the cache is stored in:

```text
/home/<your-user>/.local/share/Fiamy/Fiamy/cache/audio
```

In this branch, newly cached files are saved with readable names whenever possible.

### Latest Linux package refresh

The Linux package was refreshed on **April 23, 2026** with:

- lower visualizer CPU usage
- smoother and slower visualizer bars
- rebuilt `.deb` installer from `linux-qt6`

## 🪟 Windows (branch `windows-legacy`)

The Windows branch is preserved as a reference for the historical flow and system-specific packaging.

## 🛠️ Stack

- **Qt 6**
- **QML**
- **C++17**
- **CMake**
- **yt-dlp**
- **FFmpeg / Qt Multimedia**
- **miniaudio** (platform-dependent)

## ▶️ Local development

### Linux

```bash
cmake -S . -B build-linux
cmake --build build-linux -j4
./build-linux/fiamy
```

### Windows

Use the `windows-legacy` branch and open the project in Qt Creator with the corresponding kit.

## 🗂️ Documentation

- `docs/linux.md`
- `docs/windows.md`
- `platform/linux/README.md`
- `platform/windows/README.md`
- `packaging/linux/README.md`
- `packaging/windows/README.md`

## 📦 Releases

The project now keeps **Windows** and **Linux** releases side by side, without removing the historical Windows assets.

### 🪟 Windows release

- Release page: <https://github.com/FiammaMuscari/Fiamy/releases>
- Latest installer: [**Fiamy_Setup-1.0.1.exe**](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.1/Fiamy_Setup-1.0.1.exe)
- Release: **Fiamy v1.0.1 – Stability & packaging fixes 🎧**

### 🐧 Linux release

- Release page: <https://github.com/FiammaMuscari/Fiamy/releases/tag/v1.0.2-linux-beta>
- Latest installer: [**fiamy_1.0_amd64.deb**](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.2-linux-beta/fiamy_1.0_amd64.deb)
- Release: **Fiamy v1.0.2 – Linux installer beta 🎧**
- Refreshed package date: **April 23, 2026**

- Branch: **`linux-qt6`**
- Installer format: **`.deb`**
- Build output:

```text
dist/linux-deb/fiamy_1.0_amd64.deb
```

Install it with:

```bash
sudo apt install ./dist/linux-deb/fiamy_1.0_amd64.deb
```

This Linux package includes the app, desktop entry, icon, and bundled `yt-dlp` for a smoother first run.

## 🚀 Next step

The next natural step for the repository is to prepare:

- Linux packaging
- Windows packaging
- installers with the required Qt6 dependencies
