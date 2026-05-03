import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    implicitHeight: 32

    property QtObject playerManager: null

    spacing: 12

    property real volumeValue: 0.7

    Component.onCompleted: {
        if (root.playerManager) {
            root.playerManager.volume = volumeValue
        }
    }


    Text {
        id: volumeIcon
        text: volumeValue < 0.01 ? "OFF" : volumeValue < 0.5 ? "LOW" : "VOL"
        color: "#B0A8C0"
        font.pixelSize: 11
        font.bold: true
    }

    Item {
        id: volumeSlider
        Layout.fillWidth: true
        height: 30

        Rectangle {
            id: volumeBackground
            anchors.centerIn: parent
            width: parent.width
            height: 8
            radius: 4
            color: "#0d0d15"
            border.color: "#3a3a4e"
            border.width: 1

            Rectangle {
                id: volumeFill
                width: root.volumeValue * parent.width
                height: parent.height
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#D4A5C4" }
                    GradientStop { position: 1.0; color: "#A8B4E2" }
                }
            }
        }

        Rectangle {
            id: volumeHandle
            width: 18
            height: 18
            radius: 9
            color: "#D4A5C4"
            y: (parent.height - height) / 2
            x: root.volumeValue * (parent.width - width)
            border.color: "#ffffff"
            border.width: 2

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 2
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: "#60000000"
                z: -1
            }
        }

        MouseArea {
            anchors.fill: parent

            function updateVolume(mouse) {
                var newVolume = mouse.x / width
                newVolume = Math.max(0, Math.min(1, newVolume))
                root.volumeValue = newVolume
                if (root.playerManager) {
                        root.playerManager.volume = volumeValue
                    }
            }

            onPressed: function(mouse) { updateVolume(mouse) }
            onPositionChanged: function(mouse) { updateVolume(mouse) }
        }
    }

    Text {
        text: Math.round(root.volumeValue * 100) + "%"
        font.pixelSize: 11
        color: "#B0A8C0"
        font.bold: true
        Layout.preferredWidth: 35
    }
}
