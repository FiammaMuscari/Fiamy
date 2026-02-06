import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Row {
    id: root
    property var playerManager: null

    spacing: 6

    // Botón ANTERIOR
    Button {
        id: prevButton
        width: 45
        height: 45
        enabled: root.playerManager && root.playerManager.playlistCount > 0
        hoverEnabled: false

        background: Rectangle {
            radius: 22.5
            color: parent.enabled ? "#8894c2" : "#3a3a4e"
            border.color: parent.enabled ? "#a8b4e2" : "#4a4a5e"
            border.width: 2

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 2
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: "#40000000"
                z: -1
                visible: parent.parent.enabled
            }
        }

        contentItem: Item {
            Canvas {
                anchors.centerIn: parent
                width: 20
                height: 20
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = parent.parent.parent.enabled ? "#FFFFFF" : "#606070"

                    // Barra vertical izquierda
                    ctx.fillRect(2, 3, 2, 14)

                    // Triángulo apuntando a la izquierda
                    ctx.beginPath()
                    ctx.moveTo(17, 3)
                    ctx.lineTo(17, 17)
                    ctx.lineTo(7, 10)
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }

        onClicked: {
            if (root.playerManager) {
                root.playerManager.previousSong()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse.accepted = false
        }
    }

    // Botón -5s (flecha doble izquierda)
    Button {
        id: seekBackButton
        width: 32
        height: 32
        enabled: root.playerManager && root.playerManager.currentIndex >= 0
        hoverEnabled: false

        background: Rectangle {
            radius: 16
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: parent.parent.enabled ? "#D4A5D8" : "#3a3a4e"
                }
                GradientStop {
                    position: 1.0
                    color: parent.parent.enabled ? "#B485C8" : "#2a2a3a"
                }
            }
            border.color: parent.parent.enabled ? "#e4c5e8" : "#4a4a5e"
            border.width: 1.5

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: "#40000000"
                z: -1
                visible: parent.parent.enabled
            }
        }

        contentItem: Item {
            Canvas {
                anchors.centerIn: parent
                width: 18
                height: 18
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = parent.parent.parent.enabled ? "#FFFFFF" : "#606070"

                    // Primera flecha (izquierda)
                    ctx.beginPath()
                    ctx.moveTo(8, 4)
                    ctx.lineTo(8, 14)
                    ctx.lineTo(3, 9)
                    ctx.closePath()
                    ctx.fill()

                    // Segunda flecha (derecha)
                    ctx.beginPath()
                    ctx.moveTo(15, 4)
                    ctx.lineTo(15, 14)
                    ctx.lineTo(10, 9)
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }

        onClicked: {
            if (root.playerManager) {
                root.playerManager.seekRelative(-5000)
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse.accepted = false
        }
    }

    // Botón PLAY/PAUSE (más grande)
    Button {
        id: playButton
        width: 65
        height: 65
        enabled: root.playerManager && root.playerManager.playlistCount > 0
        hoverEnabled: false

        background: Rectangle {
            radius: 32.5
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: parent.parent.enabled ? "#D4A5C4" : "#3a3a4e"
                }
                GradientStop {
                    position: 1.0
                    color: parent.parent.enabled ? "#B495C4" : "#2a2a3e"
                }
            }
            border.color: parent.parent.enabled ? "#f4d5e4" : "#4a4a5e"
            border.width: 2.5

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 2
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: "#60000000"
                z: -1
                visible: parent.parent.enabled
            }
        }

        contentItem: Item {
            Canvas {
                id: playPauseCanvas
                anchors.centerIn: parent
                width: 28
                height: 28

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = root.playerManager && root.playerManager.isPlaying ? "#FFFFFF" : "#FFFFFF"

                    if (root.playerManager && root.playerManager.isPlaying) {
                        // PAUSA → dos barras
                        ctx.fillRect(6, 4, 5, 20)
                        ctx.fillRect(17, 4, 5, 20)
                    } else {
                        // PLAY → triángulo
                        ctx.beginPath()
                        ctx.moveTo(8, 4)
                        ctx.lineTo(8, 24)
                        ctx.lineTo(24, 14)
                        ctx.closePath()
                        ctx.fill()
                    }
                }

                Component.onCompleted: requestPaint()

                Connections {
                    target: root.playerManager
                    function onIsPlayingChanged() {
                        playPauseCanvas.requestPaint()
                    }
                }
            }

        }

        onClicked: {
            if (root.playerManager) {
                root.playerManager.togglePlayPause()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse.accepted = false
        }
    }

    // Botón +5s (flecha doble derecha)
    Button {
        id: seekForwardButton
        width: 32
        height: 32
        enabled: root.playerManager && root.playerManager.currentIndex >= 0
        hoverEnabled: false

        background: Rectangle {
            radius: 16
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: parent.parent.enabled ? "#D4A5D8" : "#3a3a4e"
                }
                GradientStop {
                    position: 1.0
                    color: parent.parent.enabled ? "#B485C8" : "#2a2a3a"
                }
            }
            border.color: parent.parent.enabled ? "#e4c5e8" : "#4a4a5e"
            border.width: 1.5

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: "#40000000"
                z: -1
                visible: parent.parent.enabled
            }
        }

        contentItem: Item {
            Canvas {
                anchors.centerIn: parent
                width: 18
                height: 18
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = parent.parent.parent.enabled ? "#FFFFFF" : "#606070"

                    // Primera flecha (izquierda)
                    ctx.beginPath()
                    ctx.moveTo(3, 4)
                    ctx.lineTo(3, 14)
                    ctx.lineTo(8, 9)
                    ctx.closePath()
                    ctx.fill()

                    // Segunda flecha (derecha)
                    ctx.beginPath()
                    ctx.moveTo(10, 4)
                    ctx.lineTo(10, 14)
                    ctx.lineTo(15, 9)
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }

        onClicked: {
            if (root.playerManager) {
                root.playerManager.seekRelative(5000)
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse.accepted = false
        }
    }

    // Botón SIGUIENTE
    Button {
        id: nextButton
        width: 45
        height: 45
        enabled: root.playerManager && root.playerManager.playlistCount > 0
        hoverEnabled: false

        background: Rectangle {
            radius: 22.5
            color: parent.enabled ? "#8894c2" : "#3a3a4e"
            border.color: parent.enabled ? "#a8b4e2" : "#4a4a5e"
            border.width: 2

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 2
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: "#40000000"
                z: -1
                visible: parent.parent.enabled
            }
        }

        contentItem: Item {
            Canvas {
                anchors.centerIn: parent
                width: 20
                height: 20
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = parent.parent.parent.enabled ? "#FFFFFF" : "#606070"

                    // Triángulo apuntando a la derecha
                    ctx.beginPath()
                    ctx.moveTo(3, 3)
                    ctx.lineTo(3, 17)
                    ctx.lineTo(13, 10)
                    ctx.closePath()
                    ctx.fill()

                    // Barra vertical derecha
                    ctx.fillRect(16, 3, 2, 14)
                }
            }
        }

        onClicked: {
            if (root.playerManager) {
                root.playerManager.nextSong()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse.accepted = false
        }
    }
}
