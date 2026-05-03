# Fiamy v1.0.2 Linux packaging refresh

> **Status on May 3, 2026:** this draft is kept only as historical context. The published `v1.0.2` Linux artifacts need to be rebuilt and re-audited before these claims can be reused.

## Why this note was retired

A real post-release audit found that the current AppImage still has portability issues, including:

- missing runtime libraries such as `libapparmor.so.1`
- bundled libraries that require newer host symbols such as `GLIBC_2.36`, `GLIBC_2.38`, and `MOUNT_2_40`

## What changed in packaging after this

- Linux CI now targets distro-provided Qt on `ubuntu-22.04` instead of newer prebuilt Qt binaries
- AppImage verification now fails on symbol-version errors, not only plain `=> not found`
- AppImage bundling now keeps key runtime libraries such as `libapparmor`, `libdbus-1`, `libcap`, `libmount`, `libblkid`, and `libselinux`

## Next release guidance

Do not reuse the original “no missing shared libraries / max GLIBC_2.35” text until the rebuilt artifacts are verified again from scratch.
