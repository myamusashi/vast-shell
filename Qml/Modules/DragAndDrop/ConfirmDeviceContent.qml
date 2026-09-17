pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    readonly property int fileCount: island.droppedFiles.length
    readonly property real maxContentHeight: FileListMetrics.clampHeight(fileCount, 18, 4, 120)
    readonly property real visibleHeight: maxContentHeight

    implicitWidth: FileListMetrics.clampWidth(fileNameMaxWidth + 80, 240, Number.POSITIVE_INFINITY)
    implicitHeight: visibleHeight + 80

    readonly property real fileNameMaxWidth: FileListMetrics.computeMaxWidth(island.droppedFiles, file => String(file).split("/").pop().length * 8, 280, 40)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Send to %1?").arg(root.island.selectedDevice?.name ?? "")
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            color: Colours.m3Colors.m3OnSurface
        }

        Flickable {
            Layout.preferredWidth: root.fileNameMaxWidth
            Layout.preferredHeight: root.visibleHeight
            contentWidth: width
            contentHeight: root.maxContentHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.island.droppedFiles

                    delegate: StyledText {
                        required property var modelData

                        width: parent.width
                        text: String(modelData).split("/").pop()
                        font.pixelSize: Appearance.fonts.size.small
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
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
