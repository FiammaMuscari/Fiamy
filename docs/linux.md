# 🐧 Linux

Esta guía resume el estado de la rama `linux-qt6`.

## Estado

- Qt 6 + QML funcionando
- `yt-dlp` administrado por la app
- selector de archivos funcionando
- cache local de audio
- visualizer adaptado a Linux

## Cache

Ruta típica:

```text
~/.local/share/Fiamy/Fiamy/cache/audio
```

## Pendiente

- definir formato de distribución final
- empaquetado de Qt6 para release
- revisar instalador / AppImage / `.deb`

## Flujo mínimo recomendado

### Build release

```bash
./packaging/linux/build-release.sh
```

### Carpeta portable

```bash
./packaging/linux/package-portable.sh
```

Esto genera una carpeta `dist/fiamy-linux-portable/` lista para revisar.
