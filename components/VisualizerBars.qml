import QtQuick
import "." as Components

Item {
    id: barsContainer
    anchors.fill: parent
    property var spectrum: []
    property bool isPlaying: false
    clip: true

    // 🐛 DEBUG
    onSpectrumChanged: {
        if (spectrum && spectrum.length > 0) {
            // console.log("📊 Barras recibiendo espectro:", spectrum.length, "valores")
        }
    }

    Component.onCompleted: {
        console.log("✅ VisualizerBars listo, esperando espectro...")
    }

    Row {
        id: barRow
        anchors.fill: parent
        spacing: 2
        anchors.margins: 0

        Repeater {
            id: barsRepeater
            model: {
                if (spectrum && spectrum.length > 0) {
                    return spectrum.length
                }
                return 32
            }

            Components.VisualizerBar {
                property int barCount: barsRepeater.model

                width: (barsContainer.width - (barCount - 1) * barRow.spacing) / barCount
                height: parent.height
                targetHeight: {
                    if (spectrum && spectrum[index] !== undefined) {
                        return spectrum[index]
                    }
                    return 0
                }
                isPlaying: barsContainer.isPlaying
                barIndex: index
            }
        }
    }
}
