import QtQuick
import QtQuick.Controls
import Fiamy 1.0
import "." as Components

Rectangle {
    id: root
    property bool isPlaying: false
    property var playerManager: null
    property var spectrum: []

    implicitWidth: 280
    implicitHeight: 180
    radius:8
    color: "#0d0d15"
    border.color: "#D4A5C4"
    border.width: 3
    clip: true

    AudioCaptureAnalyzer {
        id: audioCapture
        Component.onCompleted: {
            start()
            console.log("🎤 AudioCapture ")
        }
        Component.onDestruction: stop()
    }

    // 5️⃣ CANVAS CON GRID ESTÁTICO (sin animación)
    Canvas {
        id: backgroundCanvas
        anchors.fill: parent
        anchors.margins: 3

        Component.onCompleted: {
            requestPaint()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // Fondo estático (sin colorShift ni animación)
            var gradient = ctx.createLinearGradient(0, 0, width, height)
            gradient.addColorStop(0, Qt.rgba(0.12, 0.05, 0.2, 1))
            gradient.addColorStop(0.5, Qt.rgba(0.15, 0.12, 0.25, 1))
            gradient.addColorStop(1, Qt.rgba(0.1, 0.15, 0.22, 1))
            ctx.fillStyle = gradient
            ctx.fillRect(0, 0, width, height)

            // Grid horizontal estático
            ctx.strokeStyle = Qt.rgba(0.2, 0.35, 0.4, 0.5)
            ctx.lineWidth = 1
            for (var i = 0; i <= 10; i++) {
                ctx.beginPath()
                ctx.moveTo(0, i * height / 10)
                ctx.lineTo(width, i * height / 10)
                ctx.stroke()
            }

            // Grid vertical estático
            for (var j = 0; j <= 16; j++) {
                ctx.beginPath()
                ctx.moveTo(j * width / 16, 0)
                ctx.lineTo(j * width / 16, height)
                ctx.stroke()
            }
        }
    }

    // LAS BARRAS (encima del grid)
    Components.VisualizerBars {
        anchors.fill: parent
        anchors.margins: 10
        spectrum: audioCapture.spectrum
        isPlaying: root.isPlaying
    }

    // 6️⃣ INDICADOR PLAY/STOP (arriba izquierda)
    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 12
        spacing: 8
        z: 10

        // 7️⃣ PUNTITO ROJO DE ESTADO
        Rectangle {
            width: 8
            height: 8
            radius: 8
            color: root.isPlaying ? "#ff2080" : "#404040"
            anchors.verticalCenter: parent.verticalCenter

            // Glow del puntito
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 6
                height: parent.height + 6
                radius: (parent.width + 6) / 2
                color: root.isPlaying ? "#40ff2080" : "transparent"
                z: -1
            }

            // Animación de pulso cuando está playing
            SequentialAnimation on scale {
                running: root.isPlaying
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.3; duration: 600 }
                NumberAnimation { from: 1.3; to: 1.0; duration: 600 }
            }
        }

        Text {
            text: root.isPlaying ? "♪ PLAY" : "■ STOP"
            font.pixelSize: 11
            font.bold: true
            color: root.isPlaying ? "#00ffff" : "#606070"
            font.family: "Courier New"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
