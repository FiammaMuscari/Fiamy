# 🐧 Linux

This guide summarizes the state of the `linux-qt6` branch.

## Status

- Qt 6 + QML working
- app-managed `yt-dlp`
- bundled `yt-dlp` inside the package when available
- working file picker
- local audio cache
- Linux-adapted visualizer
- smoother visualizer tuned for playlist-heavy usage

## Cache

Typical path:

```text
~/.local/share/Fiamy/Fiamy/cache/audio
```

## Pending

- define the final distribution format
- package Qt6 for release
- review installer / AppImage / `.deb`

## Installation

Portable Linux asset:

```text
dist/linux-portable/fiamy-1.0.2-linux-portable-x86_64.tar.gz
```

Unpack it and run:

```bash
./fiamy-linux-portable/Fiamy.sh
```

Debian package asset:

```text
dist/linux-deb/fiamy_1.0_amd64.deb
```

Install it with:

```bash
sudo apt install ./dist/linux-deb/fiamy_1.0_amd64.deb
```

The package includes the application binary, desktop file, icon, and bundled `yt-dlp`.

## Latest package refresh

The latest Linux `.deb` was rebuilt on **April 23, 2026** from branch `linux-qt6`.

Included in this refresh:

- reduced visualizer CPU cost
- slower / smoother bar motion
- refreshed Debian package asset for the current Linux beta release

## Recommended minimal flow

### Build release

```bash
./packaging/linux/build-release.sh
```

### Portable folder

```bash
./packaging/linux/package-portable.sh
```

This creates:

- `dist/fiamy-linux-portable/`
- `dist/linux-portable/fiamy-<version>-linux-portable-x86_64.tar.gz`

### Debian package

```bash
./packaging/linux/package-deb.sh
```

This creates a `.deb` package in `dist/linux-deb/`.

The package will also include a bundled `yt-dlp` copy when the build machine has one available in `PATH`.
