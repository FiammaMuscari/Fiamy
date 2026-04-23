# Packaging / Linux

Linux packaging helpers for the active `linux-qt6` branch.

Possible formats:

- AppImage
- `.deb`
- portable tarball

## Included scripts

- `build-release.sh` → builds a release binary
- `package-portable.sh` → creates an initial portable folder
- `package-deb.sh` → creates a Debian package

If `yt-dlp` exists in `PATH` during the build, it is bundled into the package and used as the first runtime copy.

## Current packaged installer

Current Debian asset:

```text
dist/linux-deb/fiamy_1.0_amd64.deb
```

Refreshed on **April 23, 2026** with the smoother Linux visualizer changes.
