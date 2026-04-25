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
- `package-deb-trixie.sh` → builds a Debian **Trixie** package in a Trixie container
- `upload-release-assets.sh` → uploads built Linux assets to a GitHub Release tag using `gh`

The portable package now installs the app plus deployed Qt runtime files into:

```text
dist/fiamy-linux-portable/
```

and also creates:

```text
dist/linux-portable/fiamy-<version>-linux-portable-x86_64.tar.gz
```

If `yt-dlp` exists in `PATH` during the build, it is bundled into the package and used as the first runtime copy.

## Current packaged installer

Current Debian asset:

```text
dist/linux-deb/fiamy_1.0_amd64.deb
```

Refreshed on **April 23, 2026** with the smoother Linux visualizer changes.

For a distro-targeted build, see:

```text
docs/trixie-packaging.md
```

## GitHub Releases

There is also a workflow at:

```text
.github/workflows/release-linux.yml
```

When a GitHub Release is published, it builds and attaches:

- portable Linux tarball
- Ubuntu-targeted `.deb`
