# 🎧 Fiamy

Fiamy es un reproductor MP3/Youtube hecho con **Qt 6 + QML + C++**.  
Este repo ahora queda organizado para distinguir mejor el flujo de **Windows** y **Linux** sin duplicar todo el proyecto 💿

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-Open_Source-green?style=for-the-badge)](LICENSE)
[![Linux](https://img.shields.io/badge/Linux-Qt6-2ea043?style=for-the-badge&logo=linux)](https://github.com/FiammaMuscari/Fiamy/tree/linux-qt6)
[![Windows](https://img.shields.io/badge/Windows-Legacy-0078d4?style=for-the-badge&logo=windows)](https://github.com/FiammaMuscari/Fiamy/tree/windows-legacy)

</div>

## 🌿 Ramas del proyecto

- **`linux-qt6`** → rama activa para Linux / Qt6
- **`windows-legacy`** → base preservada del flujo Windows
- **`main`** → rama general / referencia del repo

> Si vas a trabajar en Linux, usa **`linux-qt6`**.  
> Si necesitas revisar el comportamiento histórico de Windows, usa **`windows-legacy`**.

## ✨ Qué hace Fiamy

- 🎵 Reproduce archivos de audio locales
- 🔗 Agrega canciones desde links de YouTube
- 📋 Descarga playlists a la cola
- 📦 Cachea audio temporalmente
- 📌 Tiene mini-player
- 🌈 Incluye visualizer reactivo

## 📁 Organización del repo

```text
.
├── components/          # UI QML compartida
├── thirdparty/          # dependencias embebidas
├── docs/                # notas por plataforma
├── platform/
│   ├── linux/           # notas y assets específicos de Linux
│   └── windows/         # notas y assets específicos de Windows
├── packaging/
│   ├── linux/           # futuro empaquetado Linux
│   └── windows/         # futuro empaquetado Windows
├── CMakeLists.txt
├── Main.qml
└── *.cpp / *.h
```

## 🐧 Linux (rama `linux-qt6`)

### Estado actual

- ✅ reproducción local
- ✅ integración YouTube con `yt-dlp`
- ✅ cache local
- ✅ visualizer adaptado a Linux
- ✅ selector de archivos funcionando

### Cache de audio

Mientras Fiamy está corriendo en Linux, el cache se guarda en:

```text
/home/<tu-usuario>/.local/share/Fiamy/Fiamy/cache/audio
```

En esta rama los archivos nuevos cacheados se guardan con nombre legible cuando es posible.

## 🪟 Windows (rama `windows-legacy`)

La rama Windows queda preservada como referencia del flujo anterior y del empaquetado específico de ese sistema.

## 🛠️ Stack

- **Qt 6**
- **QML**
- **C++17**
- **CMake**
- **yt-dlp**
- **FFmpeg / Qt Multimedia**
- **miniaudio** (según plataforma)

## ▶️ Desarrollo local

### Linux

```bash
cmake -S . -B build-linux
cmake --build build-linux -j4
./build-linux/fiamy
```

### Windows

Usar la rama `windows-legacy` y abrir el proyecto en Qt Creator con su kit correspondiente.

## 🗂️ Documentación

- `docs/linux.md`
- `docs/windows.md`
- `platform/linux/README.md`
- `platform/windows/README.md`
- `packaging/linux/README.md`
- `packaging/windows/README.md`

## 🚀 Próximo paso

El siguiente paso natural del repo es preparar:

- empaquetado Linux
- empaquetado Windows
- instaladores con las dependencias Qt6 necesarias

