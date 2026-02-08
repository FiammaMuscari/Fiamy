# 🎧 Fiamy MP3 Player

A lightweight desktop MP3 player built with **Qt + C++**, focused on streaming and downloading audio from **YouTube** in a smooth and modern way.



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
