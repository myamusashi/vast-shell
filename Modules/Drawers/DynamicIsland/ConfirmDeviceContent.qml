pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property var island

    implicitWidth: Math.max(240, confirmColumnLayout.implicitWidth + 48)
    implicitHeight: confirmColumnLayout.implicitHeight + 32

    ColumnLayout {
        id: confirmColumnLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Send to %1?").arg(root.island.selectedDevice?.name ?? "")
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                text: root.island.droppedFiles.map(f => f.split("/").pop()).join(", ")
                font.pixelSize: Appearance.fonts.size.small
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideMiddle
                maximumLineCount: 2
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.normal

            Rectangle {
                implicitWidth: Math.max(80, cancelLabel.implicitWidth + 32)
                implicitHeight: 32
                radius: Appearance.rounding.small
                color: cancelMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Error, 0.12) : "transparent"

                StyledText {
                    id: cancelLabel

                    anchors.centerIn: parent
                    text: qsTr("Cancel")
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    color: Colours.m3Colors.m3Error
                }

                MArea {
                    id: cancelMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.island.dismiss()
                }
            }

            Rectangle {
                implicitWidth: Math.max(80, sendLabel.implicitWidth + 32)
                implicitHeight: 32
                radius: Appearance.rounding.small
                color: sendMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"

                StyledText {
                    id: sendLabel

                    anchors.centerIn: parent
                    text: qsTr("Send")
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    color: Colours.m3Colors.m3Primary
                }

                MArea {
                    id: sendMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.island.startTransfer()
                }
            }
        }
    }
}
