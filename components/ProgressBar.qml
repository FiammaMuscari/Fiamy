import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var playerManager: null
    spacing: 8
    implicitHeight: 56

    // Textos de tiempo
    RowLayout {
        Layout.fillWidth: true
        Text {
            id: currentTimeText
            text: playerManager && playerManager.currentIndex >= 0
                  ? formatTime(playerManager.currentPosition) : "0:00"
            font.pixelSize: 12
            color: "#B0A8C0"
            font.bold: true
        }
        Item { Layout.fillWidth: true }
        Text {
            id: totalTimeText
            text: playerManager && playerManager.currentIndex >= 0
                  ? formatTime(playerManager.currentDuration) : "0:00"
            font.pixelSize: 12
            color: "#B0A8C0"
            font.bold: true
        }
    }

    // Barra de progreso
    Item {
        Layout.fillWidth: true
        height: 30

        Rectangle {
            id: progressBackground
            anchors.centerIn: parent
            width: parent.width
            height: 8
            radius: 4
            color: "#0d0d15"
            border.color: "#3a3a4e"
            border.width: 1

            Rectangle {
                id: progressFill
                width: {
                    if (!playerManager || playerManager.currentIndex < 0) return 0
                    var pos = playerManager.currentPosition
                    var dur = playerManager.currentDuration
                    if (dur <= 0) return 0
                    return (pos / dur) * parent.width
                }
                height: parent.height
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#D4A5C4" }
                    GradientStop { position: 1.0; color: "#A8B4E2" }
                }
            }
        }

        // Handle draggable
        Rectangle {
            id: progressHandle
            width: 20
            height: 20
            radius: 10
            color: "#D4A5C4"
            y: (parent.height - height) / 2
            x: {
                if (!playerManager || playerManager.currentIndex < 0) return 0
                var pos = playerManager.currentPosition
                var dur = playerManager.currentDuration
                if (dur <= 0) return 0
                return (pos / dur) * (parent.width - width)
            }
            border.color: "#ffffff"
            border.width: 3

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 3
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: "#80000000"
                z: -1
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: playerManager && playerManager.currentDuration > 0
            cursorShape: Qt.ArrowCursor  // default

            onEntered: cursorShape = Qt.PointingHandCursor   // 🔹 cambia a manito al pasar mouse
            onExited: cursorShape = Qt.ArrowCursor

            function updatePosition(mouse) {
                if (!playerManager) return
                var dur = playerManager.currentDuration
                if (dur <= 0) return
                var newPos = (mouse.x / width) * dur
                playerManager.seek(newPos)
            }

            onPressed: updatePosition(mouse)
            onPositionChanged: if (pressed) updatePosition(mouse)
        }
    }

    // Timer para actualizar posición cada 100ms
    Timer {
        interval: 100
        running: playerManager && playerManager.isPlaying
        repeat: true
        onTriggered: {
            if (playerManager && playerManager.currentIndex >= 0) {
                currentTimeText.text = formatTime(playerManager.currentPosition)
                totalTimeText.text = formatTime(playerManager.currentDuration)
            }
        }
    }

    // Función de ayuda para mostrar mm:ss
    function formatTime(ms) {
        if (!ms || ms < 0) return "0:00"
        var totalSeconds = Math.floor(ms / 1000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }
}
