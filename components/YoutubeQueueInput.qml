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
    property real currentDownloadPercent: 0
    property string currentDownloadTitle: ""
    property string submittedUrl: ""
    property bool requestInProgress: false

    spacing: 8
    Layout.fillWidth: true
    Layout.preferredHeight: 104
    Layout.maximumHeight: 104

    property YoutubeDownloader youtubeDownloader: YoutubeDownloader {}
    property string statusMessage: "Paste YouTube URL here..."
    property string pendingUrl: ""
    readonly property string defaultStatusMessage: "Paste YouTube URL here..."

    function resetDownloadState() {
        downloadedCount = 0
        totalToDownload = 0
        currentDownloadPercent = 0
        currentDownloadTitle = ""
    }

    function extractYoutubeUrl(text) {
        var match = String(text).match(/(?:https?:\/\/)?(?:(?:www\.|m\.)?youtube\.com\/(?:watch\?[^\s]*v=|shorts\/|embed\/)|youtu\.be\/)[A-Za-z0-9_-]{11}[^\s]*/)
        if (!match || match.length === 0) return ""

        var url = match[0].replace(/[),.;]+$/, "")
        if (url.indexOf("http://") !== 0 && url.indexOf("https://") !== 0) {
            url = "https://" + url
        }
        return url
    }

    function submitInputText() {
        var url = extractYoutubeUrl(youtubeInput.text)
        if (url.length === 0 && youtubeInput.text.trim().length > 10) {
            url = youtubeInput.text.trim()
        }
        if (url.length === 0) return

        pendingUrl = ""
        autoSubmitTimer.stop()
        submitUrl(url)
    }

    function submitUrl(url) {
        if (requestInProgress && submittedUrl === url)
            return

        pendingUrl = ""
        autoSubmitTimer.stop()
        resetDownloadState()
        submittedUrl = url
        requestInProgress = true
        youtubeInput.text = url
        youtubeInput.cursorPosition = 0
        statusMessage = "Analyzing: " + url
        console.log("YouTube URL detected; starting download:", url)
        youtubeDownloader.getAudioUrl(url)
    }

    // Fila principal con input y botón
    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.preferredHeight: 36

        TextField {
            id: youtubeInput
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            placeholderText: root.defaultStatusMessage
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
                submitInputText()
            }

            onAccepted: {
                submitInputText()
            }

            onTextChanged: {
                if (text === root.submittedUrl) {
                    root.pendingUrl = ""
                    autoSubmitTimer.stop()
                    return
                }

                if (text.length > 10) {
                    var url = root.extractYoutubeUrl(text)
                    if (url.length > 0) {
                        if (url === root.submittedUrl) {
                            root.pendingUrl = ""
                            autoSubmitTimer.stop()
                            return
                        }
                        root.pendingUrl = url
                        autoSubmitTimer.restart()
                    }
                } else {
                    root.pendingUrl = ""
                    autoSubmitTimer.stop()
                }
            }

            Component.onCompleted: {
                youtubeInput.forceActiveFocus()
                if (typeof fiamyAutoSubmitUrl !== "undefined" && fiamyAutoSubmitUrl.length > 0) {
                    youtubeInput.text = fiamyAutoSubmitUrl
                    Qt.callLater(function() {
                        submitInputText()
                    })
                }
            }

            // Clic derecho para pegar y procesar
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    youtubeInput.paste()
                    youtubeInput.forceActiveFocus()

                    Qt.callLater(function() {
                        submitInputText()
                    })
                }
            }

            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }
        }

        // Botón agregar
        Button {
            text: "+"
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
                submitInputText()
            }
        }
    }

    Text {
        id: visibleStatus
        Layout.fillWidth: true
        Layout.preferredHeight: 16
        text: root.statusMessage === root.defaultStatusMessage ? "Ready" : root.statusMessage
        color: root.statusMessage === root.defaultStatusMessage ? "#94a3b8" : "#d8f7f2"
        font.pixelSize: 11
        font.bold: root.statusMessage !== root.defaultStatusMessage
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
    }

    Timer {
        id: autoSubmitTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (root.pendingUrl.length === 0) return
            if (root.pendingUrl === root.submittedUrl) return
            if (root.extractYoutubeUrl(youtubeInput.text) !== root.pendingUrl) return

            var url = root.pendingUrl
            root.pendingUrl = ""
            submitUrl(url)
        }
    }

    // Fila de progreso
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: "#0d0d15"
            border.color: "#404040"
            border.width: 2
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * currentDownloadPercent / 100))
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#D4A5C4" }
                    GradientStop { position: 1.0; color: "#8894c2" }
                }
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 12
                text: Math.round(currentDownloadPercent) + "%"
                color: "#ffffff"
                font.pixelSize: 12
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        // Botón cancelar (SOLO detiene descargas, NO cierra la app)
        Button {
            text: "X"
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
                requestInProgress = false
                isDownloadingPlaylist = false
                resetDownloadState()
                statusMessage = "Cancelled"
                cancelTimer.restart()
            }
        }

    }

    Connections {
        target: youtubeDownloader

        function onAudioReady(url, title, author) {
            var urlStr = String(url)
            console.log("✅ Listo:", title, "by", author)
            requestInProgress = false

            if (root.playerManager) {
                root.playerManager.addStreamToPlaylist(urlStr, title, author, totalToDownload > 1)
            }

            if (totalToDownload <= 1) {
                statusMessage = "Queued: "
                        + (title && title.length > 0 ? title : "YouTube audio")
                        + (author && author.length > 0 ? " - " + author : "")
                successTimer.restart()
            }
        }

        function onErrorOccurred(error) {
            console.log("❌ Error:", error)
            requestInProgress = false
            isDownloadingPlaylist = false
            resetDownloadState()
            statusMessage = "Error: " + error
            errorTimer.restart()
        }

        function onProgressUpdate(message) {
            console.log("📡", message)
            statusMessage = String(message)
                .replace(/^🔍\s*/, "")
                .replace(/^⬇️\s*/, "Downloading ")
                .replace(/^✅\s*/, "")
                .replace(/^❌\s*/, "Error: ")
        }

        function onYtdlpDownloading(message) {
            console.log("📡", message)
            statusMessage = String(message)
                .replace(/^⬇️\s*/, "")
                .replace(/^✅\s*/, "")
        }

        function onDownloadCountChanged(downloaded, total) {
            downloadedCount = downloaded
            totalToDownload = total
            isDownloadingPlaylist = (total > 0 && downloaded < total)

            if (downloaded >= total && total > 0) {
                isDownloadingPlaylist = false
                currentDownloadPercent = 100
                requestInProgress = false
                statusMessage = total + " songs added"
                successTimer.restart()
            }
        }

        function onDownloadProgressChanged(current, total, percent, title) {
            downloadedCount = Math.max(0, current - 1)
            totalToDownload = total
            currentDownloadPercent = Math.max(0, Math.min(100, percent))
            currentDownloadTitle = title
            isDownloadingPlaylist = total > 0 && current <= total
            statusMessage = "Downloading " + current + "/" + total + " - " + Math.round(currentDownloadPercent) + "% - " + title
        }
    }

    Timer {
        id: errorTimer
        interval: 4000
        onTriggered: {
            statusMessage = root.defaultStatusMessage
            resetDownloadState()
        }
    }

    Timer {
        id: successTimer
        interval: 10000
        onTriggered: {
            statusMessage = root.defaultStatusMessage
            resetDownloadState()
        }
    }

    Timer {
        id: cancelTimer
        interval: 2000
        onTriggered: {
            statusMessage = root.defaultStatusMessage
        }
    }
}
