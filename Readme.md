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
- ✅ working file picker

### Audio cache

While Fiamy is running on Linux, the cache is stored in:

```text
/home/<your-user>/.local/share/Fiamy/Fiamy/cache/audio
```

In this branch, newly cached files are saved with readable names whenever possible.

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

## 🚀 Next step

The next natural step for the repository is to prepare:

- Linux packaging
- Windows packaging
- installers with the required Qt6 dependencies

