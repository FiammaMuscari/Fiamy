import QtQuick
import QtQuick.Controls
import QtMultimedia
import Qt.labs.platform
import QtQuick.Window
import "components"

Window {
    id: mainWindow
    width: 360
    height: 680
    visible: true
    title: "Pastel MP3 ♡"
    color: "transparent"

    flags: Qt.FramelessWindowHint | Qt.Window | Qt.WindowStaysOnTopHint

    // ✅ ESTADOS DE LA VENTANA
    property bool isMinimizedMode: false
    property real normalWidth: 360
    property real normalHeight: 680
    property real bookmarkWidth: 50
    property real bookmarkHeight: 180

    property real savedX: 0
    property real savedY: 0
    property bool firstMinimize: true
    property bool isVerticalBookmark: true

    PlayerManager {
        id: playerManager
    }

    // ✅ FUNCIONES PARA MINIMIZAR/RESTAURAR
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

    // ✅ BARRA DE TÍTULO (solo en modo normal)
    Rectangle {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: "transparent"
        z: 100
        visible: !isMinimizedMode

        MouseArea {
            anchors.fill: parent
            property point lastMousePos: Qt.point(0, 0)

            onPressed: {
                lastMousePos = Qt.point(mouseX, mouseY)
            }

            onPositionChanged: {
                if (pressed) {
                    mainWindow.x += mouseX - lastMousePos.x
                    mainWindow.y += mouseY - lastMousePos.y
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
                    text: "×"
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

    // ✅ BOOKMARK MINIMIZADO
    BookmarkPlayer {
        anchors.fill: parent
        visible: isMinimizedMode
        z: 200
        playerManager: playerManager
        isVertical: isVerticalBookmark

        onRestoreRequested: restoreWindow()
        onSnapToEdgeRequested: snapToEdge()
    }

    // ✅ PLAYER CARD
    PlayerCard {
        id: playerCard
        anchors.fill: parent
        anchors.margins: 16
        playerManager: playerManager
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
        title: "Select MP3"
        nameFilters: ["Audio files (*.mp3 *.wav *.m4a *.ogg *.flac)"]
        fileMode: FileDialog.OpenFiles

        onAccepted: {
            playerManager.addFiles(fileDialog.files)
        }
    }
}
