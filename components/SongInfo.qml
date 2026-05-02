import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var playerManager: null

    function currentSongTitle() {
        if (!playerManager || playerManager.playlistCount === 0 || playerManager.currentIndex < 0)
            return "Title"

        var song = playerManager.playlist[playerManager.currentIndex]
        if (song && song.title)
            return song.title
        if (song && song.name)
            return song.name.replace(/\s+-\s+[^-]+$/, "").replace(/\.(mp3|m4a|mp4|aac|webm|opus|ogg|flac|wav)$/i, "")

        return playerManager.currentSongTitle || playerManager.currentSongName || "Title"
    }

    function currentSongAuthor() {
        if (!playerManager || playerManager.playlistCount === 0 || playerManager.currentIndex < 0)
            return ""

        var song = playerManager.playlist[playerManager.currentIndex]
        if (song && song.author)
            return song.author

        return playerManager.currentSongAuthor || ""
    }

    function currentSongSource() {
        if (!playerManager || playerManager.playlistCount === 0 || playerManager.currentIndex < 0)
            return ""

        var song = playerManager.playlist[playerManager.currentIndex]
        return song && song.source ? song.source : ""
    }

    // Texto dinámico del contador de canciones
    property string songInfoText: playerManager ?
        (playerManager.playlistCount === 0 ?
         "No song queued" :
         (playerManager.currentIndex >= 0 ?
          "Playing " + (playerManager.currentIndex + 1) + " of " + playerManager.playlistCount :
          playerManager.playlistCount + " songs queued"))
        : ""

    implicitHeight: 158
    radius: 14
    color: "#111827"
    border.color: playerManager && playerManager.currentIndex >= 0 ? "#5eead4" : "#3a3a4e"
    border.width: 2

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Text {
            id: nowPlayingLabel
            text: playerManager && playerManager.currentIndex >= 0 ? "CURRENT SONG" : "QUEUE"
            font.pixelSize: 11
            font.bold: true
            color: playerManager && playerManager.currentIndex >= 0 ? "#5eead4" : "#8894c2"
            width: parent.width
            horizontalAlignment: Text.AlignLeft
        }

        // Nombre de la canción actual
        Text {
            id: songTitle
            text: "Title: " + root.currentSongTitle()
            font.pixelSize: 16
            minimumPixelSize: 8
            fontSizeMode: Text.HorizontalFit
            font.bold: true
            color: "#f5d6e7"
            wrapMode: Text.NoWrap
            maximumLineCount: 1
            clip: false
            width: parent.width
            horizontalAlignment: Text.AlignLeft
        }

        Text {
            id: songAuthor
            text: "Artist: " + root.currentSongAuthor()
            visible: root.currentSongAuthor().length > 0
            font.pixelSize: 15
            minimumPixelSize: 9
            fontSizeMode: Text.HorizontalFit
            font.bold: true
            color: "#d8f7f2"
            elide: Text.ElideNone
            width: parent.width
            horizontalAlignment: Text.AlignLeft
        }

        // Contador de la canción
        Text {
            id: songCounter
            text: "Queue: " + root.songInfoText
            font.pixelSize: 11
            color: "#8894c2"
            width: parent.width
            horizontalAlignment: Text.AlignLeft
        }

        Text {
            id: songSource
            text: root.currentSongSource().length > 0 ? "Source: " + root.currentSongSource() : ""
            visible: text.length > 0
            font.pixelSize: 11
            color: "#8894c2"
            width: parent.width
            horizontalAlignment: Text.AlignLeft
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
