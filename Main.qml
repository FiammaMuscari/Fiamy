import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Qt.labs.platform
import QtQuick.Window
import Fiamy 1.0

Window {
    id: mainWindow
    width: 420
    height: 720
    visible: true
    title: "Pastel MP3 ♡"
    color: "transparent"

    flags: Qt.FramelessWindowHint | Qt.Window | Qt.WindowStaysOnTopHint

    property bool disableAutoplay: typeof fiamyDisableAutoplay !== "undefined" && fiamyDisableAutoplay
    property bool isMinimizedMode: false
    property real normalWidth: 420
    property real normalHeight: 720
    property real bookmarkWidth: 50
    property real bookmarkHeight: 180

    property real savedX: 0
    property real savedY: 0
    property bool firstMinimize: true
    property bool isVerticalBookmark: true

    Item {
        id: playerManager
        property var player
        property var playlist: []
        property int currentIndex: -1
        property bool isPlaying: false
        property int maxPlaylistSize: 50
        property int playlistCount: 0
        property alias mediaPlayer: player
        property alias volume: audioOutput.volume
        property real currentPosition: 0
        property real currentDuration: 0
        property string currentSongName: "Title"
        property string currentSongTitle: "Title"
        property string currentSongAuthor: ""

        function refreshCurrentSongName() {
            if (currentIndex >= 0 && currentIndex < playlistCount) {
                var song = playlist[currentIndex]
                currentSongTitle = song.title || song.name.replace(/\.(mp3|m4a|mp4|aac|webm|opus|ogg|flac|wav)$/i, "")
                currentSongAuthor = song.author || ""
                currentSongName = currentSongTitle + (currentSongAuthor.length > 0 ? " - " + currentSongAuthor : "")
            } else {
                currentSongTitle = "Title"
                currentSongAuthor = ""
                currentSongName = "Title"
            }
            console.log("🎧 UI title:", currentSongName, "index:", currentIndex, "count:", playlistCount)
        }

        onCurrentIndexChanged: refreshCurrentSongName()
        onPlaylistChanged: refreshCurrentSongName()
        onPlaylistCountChanged: refreshCurrentSongName()

        function getPosition() {
            return currentPosition
        }

        function getDuration() {
            return currentDuration
        }

        function seek(pos) {
            player.position = pos
            currentPosition = pos
        }

        // ✨ FUNCIÓN moveSong para drag & drop
        function moveSong(fromIndex, toIndex) {
            console.log("🔄 moveSong:", fromIndex, "→", toIndex)

            if (fromIndex < 0 || fromIndex >= playlist.length ||
                toIndex < 0 || toIndex >= playlist.length ||
                fromIndex === toIndex) {
                console.log("❌ Índices inválidos")
                return
            }

            var temp = playlist.slice()
            var song = temp[fromIndex]

            temp.splice(fromIndex, 1)
            temp.splice(toIndex, 0, song)

            var newCurrentIndex = currentIndex
            if (currentIndex === fromIndex) {
                newCurrentIndex = toIndex
            } else if (fromIndex < currentIndex && toIndex >= currentIndex) {
                newCurrentIndex--
            } else if (fromIndex > currentIndex && toIndex <= currentIndex) {
                newCurrentIndex++
            }

            playlist = temp
            currentIndex = newCurrentIndex
            playlistCount = playlist.length

            console.log("✅ Canción movida. Nuevo currentIndex:", currentIndex)
        }

        function removeSong(index) {
            console.log("🗑️ removeSong QML - índice:", index, "tamaño:", playlist.length)

            if (index < 0 || index >= playlist.length) {
                console.log("❌ Índice inválido")
                return
            }

            console.log("🗑️ Eliminando:", playlist[index].name)

            var temp = playlist
            temp.splice(index, 1)
            playlist = temp
            playlistCount = playlist.length

            if (index === currentIndex) {
                if (playlist.length > 0) {
                    currentIndex = Math.min(index, playlist.length - 1)
                    playSong(currentIndex)
                } else {
                    player.stop()
                    currentIndex = -1
                    isPlaying = false
                    refreshCurrentSongName()
                }
            } else if (index < currentIndex) {
                currentIndex--
            }

            console.log("✅ Eliminado. Nuevo tamaño:", playlist.length)
        }

        function removeCurrentSong() {
            if (currentIndex < 0 || playlist.length === 0) return

            playlist.splice(currentIndex, 1)
            playlistCount = playlist.length

            if (currentIndex >= playlistCount) currentIndex = playlistCount - 1

            if (playlistCount > 0) {
                playSong(currentIndex)
            } else {
                player.stop()
                currentIndex = -1
                isPlaying = false
                currentPosition = 0
                currentDuration = 0
                refreshCurrentSongName()
            }
        }

        function addSingleNext(song) {
            if (!canAddMore()) return

            var temp = playlist
            var insertPos = currentIndex >= 0 ? currentIndex + 1 : temp.length

            temp.splice(insertPos, 0, song)

            playlist = temp
            playlistCount = playlist.length

            if (currentIndex < 0) playSong(0)
        }

        function addPlaylistNext(songsArray) {
            if (!canAddMore() || songsArray.length === 0) return

            var temp = playlist
            var insertPos = currentIndex >= 0 ? currentIndex + 1 : temp.length

            temp.splice.apply(temp, [insertPos, 0].concat(songsArray))

            playlist = temp
            playlistCount = playlist.length

            if (currentIndex < 0) playSong(0)
        }

        function addStreamToPlaylist(url, title, author, isFromPlaylist) {
            if (!canAddMore()) {
                console.log("❌ Playlist llena, no se puede agregar más")
                return
            }

            var cleanTitle = title ? title.replace(/\.(mp3|m4a|mp4|aac|webm|opus|ogg|flac|wav)$/i, "") : "YouTube Stream"
            var cleanAuthor = author || "YouTube"
            var displayName = cleanTitle + (cleanAuthor.length > 0 ? " - " + cleanAuthor : "")
            var sourceUrl = String(url)
            if (sourceUrl.length > 0 && sourceUrl[0] === "/" && sourceUrl.indexOf("file://") !== 0) {
                sourceUrl = "file://" + sourceUrl
            }

            var newSong = {
                "url": sourceUrl,
                "name": displayName,
                "title": cleanTitle,
                "author": cleanAuthor,
                "source": "YouTube"
            }

            console.log("➕ Agregando stream:", displayName)

            var tempPlaylist = playlist.slice()
            var insertPos

            if (isFromPlaylist === true) {
                insertPos = tempPlaylist.length
                console.log("   📋 De playlist, agregando al final en posición:", insertPos)
            } else {
                insertPos = currentIndex >= 0 ? currentIndex + 1 : tempPlaylist.length
                console.log("   🎵 Individual, agregando después de actual en posición:", insertPos)
            }

            tempPlaylist.splice(insertPos, 0, newSong)

            playlist = tempPlaylist
            playlistCount = playlist.length
            refreshCurrentSongName()

            console.log("✅ Stream agregado. Total en cola:", playlistCount)

            if (currentIndex < 0) {
                if (mainWindow.disableAutoplay) {
                    currentIndex = 0
                    refreshCurrentSongName()
                    console.log("⏸️ Autoplay deshabilitado por entorno")
                } else {
                    console.log("▶️ Iniciando reproducción automática")
                    playSong(0)
                }
            }
        }

        function seekRelative(ms) {
            if (currentIndex < 0) return
            var newPos = player.position + ms
            if (newPos < 0) newPos = 0
            if (newPos > player.duration) newPos = player.duration
            seek(newPos)
        }

        Timer {
            id: positionTimer
            interval: 100
            repeat: true
            running: false
            onTriggered: {
                if (currentIndex >= 0) {
                    currentPosition = player.position
                    currentDuration = player.duration
                }
            }
        }

        AudioOutput {
            id: audioOutput
            volume: 0.7
        }

        MediaPlayer {
            id: player
            audioOutput: audioOutput
            onDurationChanged: function(duration) {
                playerManager.currentDuration = duration
            }

            onPositionChanged: function(position) {
                playerManager.currentPosition = position
            }

            onPlaybackStateChanged: {
                playerManager.isPlaying = (playbackState === MediaPlayer.PlayingState)

                if (playbackState === MediaPlayer.StoppedState) {
                    console.log("🔍 Player detenido - position:", player.position, "duration:", player.duration)
                }
            }

            onMediaStatusChanged: {
                console.log("📊 MediaStatus:", mediaStatus)

                if (mediaStatus === MediaPlayer.EndOfMedia) {
                    console.log("🎵 Canción TERMINADA (EndOfMedia), avanzando...")
                    Qt.callLater(playerManager.nextSong)
                }
            }

            onErrorOccurred: function(error, errorString) {
                console.log("❌ Error de reproducción:", errorString)
                Qt.callLater(playerManager.nextSong)
            }
        }

        function playSong(index) {
            if (index >= 0 && index < playlistCount) {
                currentIndex = index
                refreshCurrentSongName()
                currentPosition = 0
                currentDuration = 0
                player.stop()
                player.source = playlist[index].url
                player.play()
                console.log("▶️ Reproduciendo:", currentSongName, "source:", playlist[index].url)
            }
        }

        function addFiles(files) {
            var tempPlaylist = playlist
            var added = 0

            for (var i = 0; i < files.length; i++) {
                if (tempPlaylist.length >= maxPlaylistSize) break

                var fileUrl = files[i].toString()
                var fileName = decodeURIComponent(fileUrl.split('/').pop())

                tempPlaylist.push({
                    "url": fileUrl,
                    "name": fileName,
                    "title": fileName.replace(/\.(mp3|m4a|mp4|aac|webm|opus|ogg|flac|wav)$/i, ""),
                    "author": "",
                    "source": "Local file"
                })
                added++
            }

            playlist = tempPlaylist
            playlistCount = playlist.length

            if (currentIndex < 0 && playlistCount > 0) playSong(0)
        }

        function nextSong() {
            if (currentIndex < playlistCount - 1) {
                playSong(currentIndex + 1)
            } else {
                player.stop()
                isPlaying = false
                currentPosition = 0
                currentDuration = 0
                currentIndex = -1
                refreshCurrentSongName()
            }
        }

        function previousSong() {
            if (player.position > 3000) {
                player.position = 0
            } else if (currentIndex > 0) {
                playSong(currentIndex - 1)
            }
        }

        function togglePlayPause() {
            if (playlistCount === 0) return
            if (currentIndex < 0) { playSong(0); return }

            if (isPlaying) player.pause()
            else player.play()
        }

        function canAddMore() { return playlistCount < maxPlaylistSize }
        function getRemainingSlots() { return maxPlaylistSize - playlistCount }
        function getCurrentSongName() {
            return currentSongName
        }
    }

    function minimizeToBookmark() {
        savedX = mainWindow.x
        savedY = mainWindow.y
        isMinimizedMode = true

        var currentScreen = Qt.application.screens[0]
        for (var i = 0; i < Qt.application.screens.length; i++) {
            var screen = Qt.application.screens[i]
            if (mainWindow.x >= screen.virtualX &&
                mainWindow.x < screen.virtualX + screen.width &&
                mainWindow.y >= screen.virtualY &&
                mainWindow.y < screen.virtualY + screen.height) {
                currentScreen = screen
                break
            }
        }

        if (firstMinimize) {
            isVerticalBookmark = false
            mainWindow.height = bookmarkWidth
            mainWindow.width = bookmarkHeight
            mainWindow.x = currentScreen.virtualX + currentScreen.width - bookmarkHeight - 10
            mainWindow.y = currentScreen.virtualY + 10
            firstMinimize = false
        } else {
            snapToEdge()
        }
    }

    function restoreWindow() {
        isMinimizedMode = false
        mainWindow.width = normalWidth
        mainWindow.height = normalHeight
        mainWindow.x = savedX
        mainWindow.y = savedY
    }

    function snapToEdge() {
        var currentScreen = Qt.application.screens[0]
        for (var i = 0; i < Qt.application.screens.length; i++) {
            var screen = Qt.application.screens[i]
            var windowCenterX = mainWindow.x + mainWindow.width / 2
            var windowCenterY = mainWindow.y + mainWindow.height / 2

            if (windowCenterX >= screen.virtualX &&
                windowCenterX < screen.virtualX + screen.width &&
                windowCenterY >= screen.virtualY &&
                windowCenterY < screen.virtualY + screen.height) {
                currentScreen = screen
                break
            }
        }

        var centerX = mainWindow.x + mainWindow.width / 2
        var centerY = mainWindow.y + mainWindow.height / 2

        var distLeft = centerX - currentScreen.virtualX
        var distRight = (currentScreen.virtualX + currentScreen.width) - centerX
        var distTop = centerY - currentScreen.virtualY
        var distBottom = (currentScreen.virtualY + currentScreen.height) - centerY

        var minDist = Math.min(distLeft, distRight, distTop, distBottom)

        if (minDist === distLeft) {
            isVerticalBookmark = true
            mainWindow.width = bookmarkWidth
            mainWindow.height = bookmarkHeight
            mainWindow.x = currentScreen.virtualX
        } else if (minDist === distRight) {
            isVerticalBookmark = true
            mainWindow.width = bookmarkWidth
            mainWindow.height = bookmarkHeight
            mainWindow.x = currentScreen.virtualX + currentScreen.width - bookmarkWidth
        } else if (minDist === distTop) {
            isVerticalBookmark = false
            mainWindow.height = bookmarkWidth
            mainWindow.width = bookmarkHeight
            mainWindow.y = currentScreen.virtualY
        } else {
            isVerticalBookmark = false
            mainWindow.height = bookmarkWidth
            mainWindow.width = bookmarkHeight
            mainWindow.y = currentScreen.virtualY + currentScreen.height - bookmarkWidth
        }

        mainWindow.x = Math.max(currentScreen.virtualX,
                               Math.min(currentScreen.virtualX + currentScreen.width - mainWindow.width,
                                       mainWindow.x))
        mainWindow.y = Math.max(currentScreen.virtualY,
                               Math.min(currentScreen.virtualY + currentScreen.height - mainWindow.height,
                                       mainWindow.y))
    }

    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        radius: 16
        height: 40
        color: "transparent"
        z: 100
        visible: !isMinimizedMode

        MouseArea {
            id: dragArea
            anchors.fill: parent
            property point lastMousePos: Qt.point(0, 0)

            onPressed: {
                lastMousePos = Qt.point(mouseX, mouseY)
            }

            onPositionChanged: {
                if (pressed) {
                    var dx = mouseX - lastMousePos.x
                    var dy = mouseY - lastMousePos.y
                    mainWindow.x += dx
                    mainWindow.y += dy
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 8

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: minimizeArea.containsMouse ? "#4a4a5a" : "#3a3a4a"
                border.color: "#5a5a6a"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "−"
                    color: "#e0e0e0"
                    font.pixelSize: 20
                    font.bold: true
                }

                MouseArea {
                    id: minimizeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: minimizeToBookmark()
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeArea.containsMouse ? "#ff4757" : "#3a3a4a"
                border.color: closeArea.containsMouse ? "#ff6b7a" : "#5a5a6a"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "x"
                    color: "#e0e0e0"
                    font.pixelSize: 24
                    font.bold: true
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Qt.quit()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    Rectangle {
        id: bookmarkMode
        anchors.fill: parent
        visible: isMinimizedMode
        radius: 8
        z: 200

        gradient: Gradient {
            orientation: isVerticalBookmark ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0.0; color: "#2d2d3d" }
            GradientStop { position: 0.5; color: "#232332" }
            GradientStop { position: 1.0; color: "#1a1a28" }
        }

        border.color: "#5eead4"
        border.width: 2

        MouseArea {
            id: bookmarkDragArea
            anchors.fill: parent
            property point dragStart: Qt.point(0, 0)
            cursorShape: Qt.SizeAllCursor

            onPressed: {
                dragStart = Qt.point(mouse.x, mouse.y)
            }

            onPositionChanged: {
                if (pressed) {
                    var dx = mouse.x - dragStart.x
                    var dy = mouse.y - dragStart.y
                    mainWindow.x += dx
                    mainWindow.y += dy
                }
            }

            onReleased: {
                snapToEdge()
            }

            onDoubleClicked: {
                restoreWindow()
            }
        }

        property var playlistBuffer: []

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6
            visible: isVerticalBookmark

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 32
                height: 32
                radius: 16
                color: playerManager.isPlaying ? "#5eead4" : "#3a3a4a"
                border.color: playerManager.isPlaying ? "#2dd4bf" : "#505065"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: playerManager.isPlaying ? "||" : ">"
                    color: playerManager.isPlaying ? "#0f172a" : "#94a3b8"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        playerManager.togglePlayPause()
                        mouse.accepted = true
                    }
                    cursorShape: Qt.PointingHandCursor
                    z: 10
                }
            }

            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: prevArea.containsMouse ? "#4a4a5a" : "#3a3a4a"
                    border.color: "#505065"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "|<"
                        color: "#94a3b8"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            playerManager.previousSong()
                            mouse.accepted = true
                        }
                        cursorShape: Qt.PointingHandCursor
                        z: 10
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: nextArea.containsMouse ? "#4a4a5a" : "#3a3a4a"
                    border.color: "#505065"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: ">|"
                        color: "#94a3b8"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            playerManager.nextSong()
                            mouse.accepted = true
                        }
                        cursorShape: Qt.PointingHandCursor
                        z: 10
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 32
                height: 32
                radius: 16
                color: restoreArea.containsMouse ? "#5eead4" : "#3a3a4a"
                border.color: restoreArea.containsMouse ? "#2dd4bf" : "#505065"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "[]"
                    color: restoreArea.containsMouse ? "#0f172a" : "#94a3b8"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: restoreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        restoreWindow()
                        mouse.accepted = true
                    }
                    cursorShape: Qt.PointingHandCursor
                    z: 10
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6
            visible: !isVerticalBookmark

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 32
                height: 32
                radius: 16
                color: restoreArea2.containsMouse ? "#5eead4" : "#3a3a4a"
                border.color: restoreArea2.containsMouse ? "#2dd4bf" : "#505065"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "[]"
                    color: restoreArea2.containsMouse ? "#0f172a" : "#94a3b8"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: restoreArea2
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        restoreWindow()
                        mouse.accepted = true
                    }
                    cursorShape: Qt.PointingHandCursor
                    z: 10
                }
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: prevArea2.containsMouse ? "#4a4a5a" : "#3a3a4a"
                    border.color: "#505065"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "|<"
                        color: "#94a3b8"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: prevArea2
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            playerManager.previousSong()
                            mouse.accepted = true
                        }
                        cursorShape: Qt.PointingHandCursor
                        z: 10
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: nextArea2.containsMouse ? "#4a4a5a" : "#3a3a4a"
                    border.color: "#505065"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: ">|"
                        color: "#94a3b8"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: nextArea2
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            playerManager.nextSong()
                            mouse.accepted = true
                        }
                        cursorShape: Qt.PointingHandCursor
                        z: 10
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 32
                height: 32
                radius: 16
                color: playerManager.isPlaying ? "#5eead4" : "#3a3a4a"
                border.color: playerManager.isPlaying ? "#2dd4bf" : "#505065"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: playerManager.isPlaying ? "||" : ">"
                    color: playerManager.isPlaying ? "#0f172a" : "#94a3b8"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        playerManager.togglePlayPause()
                        mouse.accepted = true
                    }
                    cursorShape: Qt.PointingHandCursor
                    z: 10
                }
            }
        }
    }

    // 🔥 CAMBIO CRÍTICO: PlayerCard DEBAJO del drawer (z: 50)
    Item {
        anchors.fill: parent
        anchors.margins: 16
        visible: !isMinimizedMode
        z: 50  // 🔥 z-index BAJO para que no bloquee el drawer

        PlayerCard {
            id: playerCard
            anchors.fill: parent
            playerManager: playerManager
        }
    }

    // 🔥 DRAWER ENCIMA del PlayerCard (z: 300)
    QueueDrawer {
        id: queueDrawer
        y: 16
        height: mainWindow.height - 32
        playerManager: playerManager
        z: 300  // 🔥 z-index ALTO para estar encima de todo
        visible: !isMinimizedMode
    }

    Connections {
        target: playerCard
        function onAddFilesRequested() {
            fileDialog.open()
        }
    }

    FileDialog {
        id: fileDialog
        title: "Selecciona archivos MP3"
        nameFilters: ["Audio files (*.mp3 *.wav *.m4a *.ogg *.flac)"]
        fileMode: FileDialog.OpenFiles

        onAccepted: {
            playerManager.addFiles(fileDialog.files)
        }
    }
}
