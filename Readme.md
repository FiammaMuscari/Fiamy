# 🎧 Fiamy MP3 Youtube Player

A lightweight desktop MP3 player built with **Qt + C++**, focused on streaming udio from **YouTube** in a smooth and modern way.

[![License: MIT](https://img.shields.io/badge/License-Open_Source-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue?style=for-the-badge&logo=windows)](https://github.com/FiammaMuscari/Fiamy/releases)
<div align="center">

<img width="556" height="715" alt="image (21)" src="https://github.com/user-attachments/assets/72b66244-c2a2-4cd0-86d4-d05e65d4cbef" />

<img width="508" height="696" alt="image (22)" src="https://github.com/user-attachments/assets/5358347e-c7af-44fd-8051-f3d145d245c6" />
</div>

## 📦 Download



<div align="center">
Windows Installer
  
**[⬇️ Download Fiamy v1.0.0 (Windows)](https://github.com/FiammaMuscari/Fiamy/releases/download/v1.0.0/Fiamy_Setup_v1.0.0.exe)**

*Free & Open Source • No ads • No tracking*

</div>

## ✨ Features

- 📋 **Paste YouTube links**
  - Right click → paste  
  - Or paste the link and press **➕ Add**
- 🎶 **Instant audio streaming from YouTube**
- 📥 **Download full YouTube playlists** (keeps original order)
- 🧲 **Drag & drop songs** inside the playback queue to reorder them
- 📌 **Mini-player mode**
  - Can be minimized and docked to screen edges
- 🧠 **Smart queue management**
- 🔄 Uses **yt-dlp** with **automatic updates configured**
- 🎵 **Cached audio**
  - Streamed songs are temporarily stored in:
    ```
    cache/audio
    ```
  - Cache is **automatically cleared when the app restarts**
- 🖥️ Built with **Qt (QML) + C++**



## 🛠️ Tech Stack

- **Qt 6 (QML + C++)**
- **CMake**
- **yt-dlp**
- **MinGW (Windows)**



## ▶️ Run locally (Windows)

### Option 1 — Using Qt Creator 

1. Open **Qt Creator**
2. Go to **File → Open File or Project**
3. Select:
CMakeLists.txt
4. Choose kit:
- **Desktop Qt 6.x MinGW 64-bit**
5. Click **Configure Project**
6. Press ▶ **Run**
