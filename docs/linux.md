# 🐧 Linux

This guide summarizes the state of the `linux-qt6` branch.

## Status

- Qt 6 + QML working
- app-managed `yt-dlp`
- working file picker
- local audio cache
- Linux-adapted visualizer

## Cache

Typical path:

```text
~/.local/share/Fiamy/Fiamy/cache/audio
```

## Pending

- define the final distribution format
- package Qt6 for release
- review installer / AppImage / `.deb`

## Recommended minimal flow

### Build release

```bash
./packaging/linux/build-release.sh
```

### Portable folder

```bash
./packaging/linux/package-portable.sh
```

This creates a `dist/fiamy-linux-portable/` folder ready to review.

### Debian package

```bash
./packaging/linux/package-deb.sh
```

This creates a `.deb` package in `dist/linux-deb/`.
