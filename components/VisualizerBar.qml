import QtQuick

Item {
    id: root
    property bool isPlaying: false
    property real targetHeight: 0
    property int barIndex: 0
    property real displayHeight: isPlaying ? Math.max(0.04, targetHeight) : 0.04
    property real peakHeight: displayHeight

    onTargetHeightChanged: {
        if (!root.isPlaying) {
            root.displayHeight = 0.04
            return
        }

        var boosted = Math.max(0.04, root.targetHeight)
        root.displayHeight = root.displayHeight * 0.78 + boosted * 0.22
    }

    onIsPlayingChanged: {
        if (!root.isPlaying) {
            root.displayHeight = 0.04
            root.peakHeight = 0.04
        }
    }

    // 1️⃣ BARRA PRINCIPAL CON GRADIENTE
    Rectangle {
        id: bar
        anchors.bottom: parent.bottom
        width: parent.width
        height: Math.max(2, parent.height * root.displayHeight)
        radius: 3

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ff0080" }
            GradientStop { position: 0.3; color: "#ff2099" }
            GradientStop { position: 0.5; color: "#ff40b8" }
            GradientStop { position: 0.7; color: "#D4A5C4" }
            GradientStop { position: 0.85; color: "#A8B4E2" }
            GradientStop { position: 1.0; color: "#60C0FF" }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius
            opacity: root.isPlaying ? 0.35 : 0.15

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.3; color: "#80ffffff" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.color: "#80ff00ff"
            border.width: 1
            z: -1
            opacity: root.isPlaying ? Math.min(0.45, parent.height / parent.parent.height) : 0.12
        }

        Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * root.peakHeight - 2
        width: parent.width + 2
        height: 3
        radius: 2
        color: "#00ffff"
        visible: root.isPlaying && root.displayHeight > 0.12
        opacity: 0.65

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 4
            height: parent.height + 2
            radius: parent.radius + 1
            color: "transparent"
            border.color: "#50ff00ff"
            border.width: 1
            z: -1
        }

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
    }

    Timer {
        interval: 48
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (root.displayHeight > root.peakHeight) {
                root.peakHeight = root.displayHeight
            } else {
                root.peakHeight = Math.max(root.displayHeight, root.peakHeight * 0.92)
            }
        }
    }
}
