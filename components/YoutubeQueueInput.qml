import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Fiamy 1.0

ColumnLayout {
    id: root
    property var playerManager: null
    property bool isDownloadingPlaylist: false
    property int downloadedCount: 0
    property int totalToDownload: 0

    spacing: 8
    Layout.fillWidth: true
    Layout.preferredHeight: 80
    Layout.maximumHeight: 80

    property YoutubeDownloader youtubeDownloader: YoutubeDownloader {}
    property string statusMessage: "Paste YouTube URL here..."
    property int successfulDownloads: 0
    property int failedDownloads: 0

    // Fila principal con input y botón
    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.preferredHeight: 36

        TextField {
            id: youtubeInput
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            placeholderText: statusMessage
            enabled: true

            background: Rectangle {
                radius: 8
                color: "#1a1a1a"
                border.color: parent.activeFocus ? "#8894c2" : "#404040"
                border.width: 2
            }

            color: "#ffffff"
            selectedTextColor: "#000000"
            selectionColor: "#8894c2"
            font.pixelSize: 14

            // Permitir Enter para procesar
            Keys.onReturnPressed: {
                if (youtubeInput.text.length > 10) {
                    var url = youtubeInput.text.trim()
                    youtubeInput.text = ""
                    statusMessage = "🔍 Analyzing..."
                    youtubeDownloader.getAudioUrl(url)
                }
            }

            Component.onCompleted: {
                youtubeInput.forceActiveFocus()
            }

            Shortcut {
                sequences: [StandardKey.Paste, "Shift+Insert"]
                enabled: youtubeInput.activeFocus
                onActivated: youtubeInput.paste()
            }

            // Clic derecho para pegar y procesar
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    youtubeInput.paste()
                    youtubeInput.forceActiveFocus()

                    Qt.callLater(function() {
                        if (youtubeInput.text.length > 10) {
                            var url = youtubeInput.text.trim()
                            youtubeInput.text = ""
                            statusMessage = "🔍 Analyzing..."
                            youtubeDownloader.getAudioUrl(url)
                        }
                    })
                }
            }

            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }
        }

        // Botón agregar
        Button {
            text: "➕"
            enabled: youtubeInput.text.length > 10
            Layout.preferredWidth: 42
            Layout.preferredHeight: 36

            background: Rectangle {
                radius: 8
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: parent.parent.enabled ? "#A8B4E2" : "#2a2a2a"
                    }
                    GradientStop {
                        position: 1.0
                        color: parent.parent.enabled ? "#8894c2" : "#1a1a1a"
                    }
                }
                border.color: parent.parent.enabled ? "#c8d4ff" : "#555555"
                border.width: 2
            }

            contentItem: Text {
                text: parent.text
                font.pixelSize: 18
                font.bold: true
                color: parent.parent.enabled ? "#ffffff" : "#666666"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            onClicked: {
                if (youtubeInput.text.length <= 10) return
                var url = youtubeInput.text.trim()
                youtubeInput.text = ""
                statusMessage = "🔍 Analyzing..."
                youtubeDownloader.getAudioUrl(url)
            }
        }
    }

    // Fila de progreso (solo visible durante descarga de playlist)
    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        opacity: (isDownloadingPlaylist && totalToDownload > 0) ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        // Indicador de progreso
        Rectangle {
            Layout.preferredWidth: 85
            Layout.preferredHeight: 36
            radius: 8
            color: "#1a1a1a"
            border.color: "#404040"
            border.width: 2

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: downloadedCount + "/" + totalToDownload
                    color: "#8894c2"
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "songs"
                    color: "#94a3b8"
                    font.pixelSize: 9
                }
            }
        }

        // Botón cancelar (SOLO detiene descargas, NO cierra la app)
        Button {
            text: "✖"
            Layout.preferredWidth: 42
            Layout.preferredHeight: 36

            background: Rectangle {
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#ff6b7a" }
                    GradientStop { position: 1.0; color: "#ff4757" }
                }
                border.color: "#ff8891"
                border.width: 2
            }

            contentItem: Text {
                text: parent.text
                font.pixelSize: 18
                font.bold: true
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            onClicked: {
                // SOLO cancela descargas, NO cierra nada
                console.log("🛑 Cancelando cola de descargas (NO cierra reproductor)")
                youtubeDownloader.cancelDownload()
                isDownloadingPlaylist = false
                downloadedCount = 0
                totalToDownload = 0
                statusMessage = "❌ Cancelled"
                cancelTimer.restart()
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Connections {
        target: youtubeDownloader

        function onAudioReady(url, title, author) {
            var urlStr = String(url)
            console.log("✅ Listo:", title, "by", author)
            console.log("📁 Ruta recibida:", urlStr)

            if (root.playerManager) {
                console.log("📥 Cola antes:", root.playerManager.playlistCount)
                root.playerManager.addStreamToPlaylist(urlStr, title, author, root.totalToDownload > 1)
                console.log("📥 Cola después:", root.playerManager.playlistCount)
            }

            if (totalToDownload <= 1) {
                statusMessage = "✅ Added!"
                successTimer.restart()
            }
        }

        function onErrorOccurred(error) {
            console.log("❌ Error:", error)
            isDownloadingPlaylist = false
            downloadedCount = 0
            totalToDownload = 0
            successfulDownloads = 0
            failedDownloads = 0
            statusMessage = "❌ " + error
            errorTimer.restart()
        }

        function onProgressUpdate(message) {
            console.log("📡", message)
            statusMessage = message
        }

        function onDownloadCountChanged(downloaded, total) {
            downloadedCount = downloaded
            totalToDownload = total
            isDownloadingPlaylist = (total > 1)
        }

        function onDownloadFinishedSummary(succeeded, failed, total) {
            successfulDownloads = succeeded
            failedDownloads = failed
            isDownloadingPlaylist = false

            if (total <= 1) {
                if (succeeded > 0) {
                    statusMessage = "✅ Added!"
                    successTimer.restart()
                }
                return
            }

            if (failed === 0) {
                statusMessage = "✅ " + succeeded + " songs added!"
                successTimer.restart()
            } else if (succeeded === 0) {
                statusMessage = "❌ No songs added"
                errorTimer.restart()
            } else {
                statusMessage = "⚠️ " + succeeded + " added, " + failed + " failed"
                successTimer.restart()
            }
        }
    }

    Timer {
        id: errorTimer
        interval: 4000
        onTriggered: {
            statusMessage = "Paste YouTube URL here..."
            downloadedCount = 0
            totalToDownload = 0
            successfulDownloads = 0
            failedDownloads = 0
        }
    }

    Timer {
        id: successTimer
        interval: 3000
        onTriggered: {
            statusMessage = "Paste YouTube URL here..."
            downloadedCount = 0
            totalToDownload = 0
            successfulDownloads = 0
            failedDownloads = 0
        }
    }

    Timer {
        id: cancelTimer
        interval: 2000
        onTriggered: {
            statusMessage = "Paste YouTube URL here..."
        }
    }
}
