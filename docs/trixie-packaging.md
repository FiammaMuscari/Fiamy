# Debian Trixie packaging

To produce a `.deb` that actually targets **Debian Trixie**, build it inside a
Trixie environment instead of building on a newer distro.

Why:

- `dpkg-shlibdeps` records the minimum versions from the libraries present on
  the build machine.
- If you build on a system with Qt 6.9, the resulting package can require
  `libqt6core6t64 (>= 6.9.1)` even though Trixie ships Qt 6.8.x.
- Building on Trixie makes the generated dependencies match Trixie.

## Local build inside a Trixie container

```bash
./packaging/linux/package-deb-trixie.sh
```

This produces a package in:

```text
dist/linux-deb/
```

Expected naming example:

```text
fiamy_1.0.2_trixie_amd64.deb
```

## Notes

- This is common for native Linux packages.
- If you want one artifact for many distros, an AppImage or Flatpak is usually
  easier than a single `.deb`.
