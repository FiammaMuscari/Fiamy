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

        contentItem: Text {
            text: "|<"
            color: prevButton.enabled ? "#ffffff" : "#606070"
            font.family: "Arial"
            font.pixelSize: 18
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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

        contentItem: Text {
            text: "-5"
            color: seekBackButton.enabled ? "#ffffff" : "#606070"
            font.family: "Arial"
            font.pixelSize: 12
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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

        contentItem: Text {
            text: root.playerManager && root.playerManager.isPlaying ? "||" : ">"
            color: playButton.enabled ? "#ffffff" : "#606070"
            font.family: "Arial"
            font.pixelSize: root.playerManager && root.playerManager.isPlaying ? 24 : 34
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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

        contentItem: Text {
            text: "+5"
            color: seekForwardButton.enabled ? "#ffffff" : "#606070"
            font.family: "Arial"
            font.pixelSize: 12
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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

        contentItem: Text {
            text: ">|"
            color: nextButton.enabled ? "#ffffff" : "#606070"
            font.family: "Arial"
            font.pixelSize: 18
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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
