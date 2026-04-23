import QtQuick

Item {
    id: root
    property bool isPlaying: false
    property real targetHeight: 0
    property int barIndex: 0

    // Suavizado y peak hold
    property real smoothedHeight: 0
    property real peakHeight: 0
    property real smoothingFactor: 0.7
    property real peakDecay: 0.95

    onIsPlayingChanged: {
        if (!root.isPlaying) {
            root.targetHeight = 0
            root.peakHeight = 0
        }
    }

    Timer {
        interval: 16  // 60 FPS
        running: true
        repeat: true
        onTriggered: {
            if (!root.isPlaying && root.smoothedHeight < 0.002) {
                root.smoothedHeight = 0
                root.peakHeight = 0
                return
            }

            // Suavizar altura
            root.smoothedHeight = root.smoothedHeight * root.smoothingFactor +
                                  root.targetHeight * (1 - root.smoothingFactor)

            // Peak hold
            if (root.smoothedHeight > root.peakHeight) {
                root.peakHeight = root.smoothedHeight
            } else {
                root.peakHeight *= root.peakDecay
            }
        }
    }

    // 1️⃣ BARRA PRINCIPAL CON GRADIENTE
    Rectangle {
        id: bar
        anchors.bottom: parent.bottom
        width: parent.width
        height: root.smoothedHeight <= 0 ? 0 : Math.max(2, parent.height * root.smoothedHeight)
        radius: 3
        visible: height > 0

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ff0080" }
            GradientStop { position: 0.3; color: "#ff2099" }
            GradientStop { position: 0.5; color: "#ff40b8" }
            GradientStop { position: 0.7; color: "#D4A5C4" }
            GradientStop { position: 0.85; color: "#A8B4E2" }
            GradientStop { position: 1.0; color: "#60C0FF" }
        }

        // 2️⃣ BRILLO INTERNO ANIMADO
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius
            opacity: 0.6

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.3; color: "#80ffffff" }
                GradientStop { position: 1.0; color: "transparent" }
            }

            SequentialAnimation on opacity {
                running: root.isPlaying && root.smoothedHeight > 0.1
                loops: Animation.Infinite
                NumberAnimation { from: 0.6; to: 0.9; duration: 400 }
                NumberAnimation { from: 0.9; to: 0.6; duration: 400 }
            }
        }

        // 3️⃣ GLOW EXTERIOR
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.color: "#80ff00ff"
            border.width: 1
            z: -1
            opacity: Math.min(1.0, parent.height / parent.parent.height)
        }
    }

    // 4️⃣ PEAK HOLD (pico tipo VU meter)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * root.peakHeight - 2
        width: parent.width + 2
        height: 4
        radius: 2
        color: "#00ffff"
        visible: root.peakHeight > 0.1

        // Glow del peak
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 6
            height: parent.height + 4
            radius: parent.radius + 1
            color: "transparent"
            border.color: "#80ff00ff"
            border.width: 2
            z: -1
        }
    }
}
