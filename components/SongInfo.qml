import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var playerManager: null

    // Texto dinámico del contador de canciones
    property string songInfoText: playerManager ?
        (playerManager.playlistCount === 0 ?
         "Press + to add songs" :
         "Song " + (playerManager.currentIndex + 1) + " of " + playerManager.playlistCount)
        : ""

    implicitHeight: 56
    radius: 16
    color: "#1a1a28"
    border.color: "#3a3a4e"
    border.width: 2

    Column {
        anchors.centerIn: parent
        spacing: 4
        width: parent.width - 24

        // Nombre de la canción actual
        Text {
            id: songTitle
            text: root.playerManager ? root.playerManager.getCurrentSongName() : "No songs"
            font.pixelSize: 16
            font.bold: true
            color: "#D4A5C4"
            elide: Text.ElideRight
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        // Contador de la canción
        Text {
            id: songCounter
            text: root.songInfoText
            font.pixelSize: 11
            color: "#8894c2"
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }
    }
    // Brillo sutil en la parte superior
     Rectangle {
         anchors.top: parent.top
         anchors.left: parent.left
         anchors.right: parent.right
         height: parent.height * 0.4
         radius: parent.radius
         gradient: Gradient {
             GradientStop { position: 0.0; color: "#20ffffff" }
             GradientStop { position: 1.0; color: "#00ffffff" }
         }
     }
}
