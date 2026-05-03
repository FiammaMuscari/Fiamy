# Fiamy v1.0.2 Linux packaging refresh

This release refreshes the Linux packages so Fiamy can run on more distros without the previous missing dependency errors.

The AppImage was rebuilt on Ubuntu 22.04 and audited after packaging:

- No missing shared libraries were found.
- No glibc files are bundled, including `libmvec.so.1`.
- Maximum required GLIBC version is `GLIBC_2.35`.
- No file requires `GLIBC_2.38`, `GLIBC_2.39`, `GLIBC_2.40`, `GLIBC_2.41`, or `GLIBC_2.42`.

## Which asset should I download?

| Your distro | Recommended download |
|---|---|
| Arch / CachyOS / Manjaro / EndeavourOS | `Fiamy-1.0.2-x86_64.AppImage` |
| Fedora / openSUSE / Gentoo / NixOS / other Linux | `Fiamy-1.0.2-x86_64.AppImage` |
| Debian / Ubuntu / Linux Mint / Pop!_OS / Zorin | `fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb` |
| Any Linux distro if the above fails | `fiamy-1.0.2-linux-portable-x86_64.tar.gz` |

## Important notes

- Checksums are available in `linux-sha256sums.txt`.
- Do **not** install the `.deb` on Arch/CachyOS/Manjaro. Use the AppImage or portable tarball.
- The AppImage and portable tarball include the needed Qt/ICU/Multimedia/QML/FFmpeg runtime libraries.
- The Debian/Ubuntu package installs Fiamy under `/opt/fiamy` with its own private runtime.
- Wayland is tried first and XCB is used as fallback. This is not a Wayland-only build.

## Run commands

AppImage:

```bash
chmod +x Fiamy-1.0.2-x86_64.AppImage
./Fiamy-1.0.2-x86_64.AppImage
```

If FUSE is unavailable:

```bash
./Fiamy-1.0.2-x86_64.AppImage --appimage-extract-and-run
```

Debian/Ubuntu:

```bash
sudo apt install ./fiamy_1.0.2_ubuntu-debian-bundled_amd64.deb
fiamy
```

Portable:

```bash
tar -xzf fiamy-1.0.2-linux-portable-x86_64.tar.gz
./fiamy-linux-portable/Fiamy.sh
```

## Fixed

- Fixed AppImage startup failures caused by missing runtime libraries such as ICU/Qt dependencies.
- Removed accidental glibc bundling from the AppImage.
- Rebuilt the AppImage with an older compatible GLIBC baseline.
- Added dependency verification for all packaged ELF files, not only the main binary.
- Reworked the `.deb` so it uses Fiamy's bundled runtime instead of distro-specific Qt package names.
