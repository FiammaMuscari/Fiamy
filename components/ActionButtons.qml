import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property var playerManager: null
    signal addFilesClicked()

    spacing: 10
    Layout.fillWidth: true
    Layout.preferredHeight: 42

    // ===============================
    // BOTÓN AGREGAR
    // ===============================
    Button {
        id: addButton
        text: "+ ADD"
        enabled: root.playerManager ? root.playerManager.canAddMore() : false
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        hoverEnabled: false

        background: Rectangle {
            radius: 10
            color: parent.parent.enabled ? "#000000" : "#2a2a2a"
            border.color: parent.parent.enabled ? "#ffffff" : "#555555"
            border.width: 2
        }

        contentItem: Text {
            text: {
                if (!root.playerManager) return parent.text;
                var remaining = root.playerManager.getRemainingSlots();
                return remaining > 0 ? "+ AGREGAR" : "COLA LLENA";
            }
            font.pixelSize: 12
            font.bold: true
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: root.addFilesClicked()

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse.accepted = false
        }
    }

    // ===============================
    // BOTÓN CERRAR / ELIMINAR
    // ===============================
    Button {
        id: removeButton
        text: "x"
        Layout.preferredWidth: 42
        Layout.preferredHeight: 42
        enabled: root.playerManager && root.playerManager.currentIndex >= 0
        hoverEnabled: false

        background: Rectangle {
            radius: 10
            color: parent.parent.enabled ? "#000000" : "#2a2a2a"
            border.color: parent.parent.enabled ? "#ffffff" : "#555555"
            border.width: 2
        }

        contentItem: Text {
            text: parent.text
            font.pixelSize: 26
            font.bold: true
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: {
            if (root.playerManager) {
                root.playerManager.removeCurrentSong()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse.accepted = false
        }
    }
}
