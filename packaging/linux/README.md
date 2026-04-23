# Packaging / Linux

Reserved folder for Linux packaging.

Possible formats:

- AppImage
- `.deb`
- portable tarball

## Included scripts

- `build-release.sh` → builds a release binary
- `package-portable.sh` → creates an initial portable folder
- `package-deb.sh` → creates a Debian package

If `yt-dlp` exists in `PATH` during the build, it is bundled into the package and used as the first runtime copy.
