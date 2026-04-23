# 🎧 Fiamy

Fiamy is an MP3 / YouTube desktop player built with **Qt + QML + C++**.

This repository keeps the current Linux work and the historical Windows flow side by side:

- **`linux-qt6`** → active Linux branch
- **`windows-legacy`** → preserved Windows branch
- **`main`** → project overview / shared entry point

## 📦 Downloads

| Platform | Download | Notes |
|---|---|---|
| Windows | [Fiamy_Setup-1.0.1.exe](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.1/Fiamy_Setup-1.0.1.exe) | stable Windows installer |
| Linux | [fiamy_1.0_amd64.deb](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.2-linux-beta/fiamy_1.0_amd64.deb) | Linux beta installer refreshed on **April 23, 2026** |

## ✨ Features

- local audio playback
- YouTube link support
- playlist queueing
- temporary audio cache
- mini-player mode
- reactive visualizer

## 🐧 Linux status

The current Linux work lives on **`linux-qt6`**.

Latest Linux packaging refresh:

- reduced visualizer CPU usage
- smoother / slower visualizer bars
- refreshed `.deb` package build
- bundled `yt-dlp` when available during packaging

Install on Ubuntu / Debian based systems with:

```bash
sudo apt install ./fiamy_1.0_amd64.deb
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

## 📚 Extra notes

Linux packaging notes added in this branch:

- `docs/linux.md`
- `packaging/linux/README.md`
- `platform/linux/README.md`

## 🔗 Releases

- All releases: <https://github.com/FiammaMuscari/Fiamy/releases>
- Linux beta release: <https://github.com/FiammaMuscari/Fiamy/releases/tag/v1.0.2-linux-beta>
