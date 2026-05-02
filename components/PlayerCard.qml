import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Components

Rectangle {
    id: root
    property var playerManager: null
    signal addFilesRequested()

    radius: 28
    border.color: "#505065"
    border.width: 3

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#2d2d3d" }
        GradientStop { position: 0.3; color: "#232332" }
        GradientStop { position: 0.7; color: "#1a1a28" }
        GradientStop { position: 1.0; color: "#12121d" }
    }

    // Sombra externa
    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: parent.radius + 6
        color: "transparent"
        border.color: "#30000000"
        border.width: 6
        z: -1
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -12
        radius: parent.radius + 12
        color: "transparent"
        border.color: "#20000000"
        border.width: 12
        z: -2
    }

    // Brillo superior
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.25
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#40ffffff" }
            GradientStop { position: 0.5; color: "#20ffffff" }
            GradientStop { position: 1.0; color: "#00ffffff" }
        }
        z: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 0  // ✅ Ahora controlamos el spacing manualmente

        // 🎵 VISUALIZADOR
        Components.AudioVisualizer {
            Layout.fillWidth: true
            Layout.preferredHeight: 130
            Layout.minimumHeight: 130
            Layout.maximumHeight: 130
            isPlaying: root.playerManager ? root.playerManager.isPlaying : false
            playerManager: root.playerManager
        }

        Item { Layout.preferredHeight: 8 }  // ✅ Espaciador

        // ℹ️ INFO CANCIÓN
        Components.SongInfo {
            Layout.fillWidth: true
            Layout.preferredHeight: 158
            Layout.maximumHeight: 158
            playerManager: root.playerManager
        }

        Item { Layout.preferredHeight: 6 }  // ✅ Espaciador

        // ⏱ PROGRESO
        Components.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.maximumHeight: 28
            playerManager: root.playerManager
        }

        Item { Layout.preferredHeight: 8 }  // ✅ MÁS espacio antes de botones

        // ⏯ CONTROLES
        Components.PlayerControls {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 68
            Layout.maximumHeight: 68
            playerManager: root.playerManager
        }

        Item { Layout.preferredHeight: 4 }  // ✅ MENOS espacio después de botones

        // 🔽 PEGAR YOUTUBE ACÁ
        Components.YoutubeQueueInput {
            Layout.fillWidth: true
            playerManager: root.playerManager
        }

        Item { Layout.preferredHeight: 4 }  // ✅ Espaciador

        // 🔊 VOLUMEN
        Components.VolumeControl {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.maximumHeight: 28
            playerManager: root.playerManager
        }

        Item { Layout.preferredHeight: 4 }  // ✅ Espaciador

        // ➕➖ ACCIONES
        Components.ActionButtons {
            id: actionButtons
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.maximumHeight: 38
            playerManager: root.playerManager

            onAddFilesClicked: {
                root.addFilesRequested()
            }
        }
    }
}
