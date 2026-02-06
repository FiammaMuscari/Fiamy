import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var playerManager
    property bool drawerOpen: false

    width: drawerOpen ? 272 : 32
    height: parent.height
    x: 0
    z: 200
    color: "transparent"

    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        id: queuePanel
        width: 240
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: 12
        color: "#1a1a28"
        border.color: "#505065"
        border.width: 2
        visible: drawerOpen
        opacity: drawerOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 8
                color: "#232332"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8

                    Text {
                        text: "Cola de reproducción"
                        color: "#5eead4"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Text {
                        text: playerManager
                              ? playerManager.playlistCount + (playerManager.playlistCount === 1 ? " canción" : " canciones")
                              : "0 canciones"
                        color: "#94a3b8"
                        font.pixelSize: 11
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4
                clip: true

                model: playerManager ? playerManager.playlistCount : 0

                delegate: Rectangle {
                    required property int index

                    width: list.width - 10
                    height: 65
                    radius: 8

                    property bool isCurrent: index === playerManager.currentIndex
                    property var songData: playerManager.playlist[index]

                    color: isCurrent ? "#2d4d5d" : "#1f1f2f"
                    border.color: isCurrent ? "#5eead4" : "#3a3a4a"
                    border.width: isCurrent ? 2 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (index !== playerManager.currentIndex) {
                                        playerManager.playSong(index)
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 4

                                Text {
                                    text: "#" + (index + 1)
                                    color: isCurrent ? "#5eead4" : "#64748b"
                                    font.pixelSize: 10
                                    font.bold: isCurrent
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: songData && songData.name ? songData.name.replace(/\.[^/.]+$/, "") : ""
                                    color: isCurrent ? "#ffffff" : "#e0e0e0"
                                    elide: Text.ElideRight
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: deleteArea.pressed ? "#3a4a5a" : (deleteArea.containsMouse ? "#2a3a4a" : "#232332")
                            border.color: "#5eead4"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: "#ffffff"
                                font.pixelSize: 20
                                font.bold: true
                            }

                            MouseArea {
                                id: deleteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    console.log("🗑️ CLICK en índice:", index)
                                    playerManager.removeSong(index)
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: list.count === 0
                    anchors.centerIn: parent
                    text: "No hay canciones\nen la cola"
                    color: "#64748b"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Rectangle {
        width: 32
        height: 60
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 8
        radius: 8
        color: "#232332"
        border.color: drawerOpen ? "#5eead4" : "#505065"
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: drawerOpen ? "◄" : "►"
            color: "#e0e0e0"
            font.pixelSize: 14
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: drawerOpen = !drawerOpen
        }
    }
}
