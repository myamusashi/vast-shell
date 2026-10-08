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

    required property bool active
    required property var  island

    readonly property int  fileCount: island.droppedFiles.length
    readonly property real fileNameMaxWidth: FileListMetrics.computeMaxWidth(island.droppedFiles, file => String(file).split("/").pop().length * 8, 280, 40)
    readonly property real maxContentHeight: FileListMetrics.clampHeight(fileCount, 18, 4, 120)
    readonly property real visibleHeight: maxContentHeight

    implicitHeight: visibleHeight + 80
    implicitWidth: FileListMetrics.clampWidth(fileNameMaxWidth + 80, 240, Number.POSITIVE_INFINITY)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            text: qsTr("Send to %1?").arg(root.island.selectedDevice?.name ?? "")
        }

        Flickable {
            Layout.preferredHeight: root.visibleHeight
            Layout.preferredWidth: root.fileNameMaxWidth
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: root.maxContentHeight
            contentWidth: width
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Column {
                spacing: 4
                width: parent.width

                Repeater {
                    model: root.island.droppedFiles
                    delegate: StyledText {
                        required property var modelData

                        color: Colours.m3Colors.m3OnSurfaceVariant
                        elide: Text.ElideMiddle
                        font.pixelSize: Appearance.fonts.size.small
                        horizontalAlignment: Text.AlignHCenter
                        text: String(modelData).split("/").pop()
                        width: parent.width
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.normal

            Rectangle {
                color: cancelMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Error, 0.12) : "transparent"
                implicitHeight: 32
                implicitWidth: Math.max(80, cancelLabel.implicitWidth + 32)
                radius: Appearance.rounding.small

                StyledText {
                    id: cancelLabel

                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3Error
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: qsTr("Cancel")
                }

                MArea {
                    id: cancelMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.island.dismiss()
                }
            }

            Rectangle {
                color: sendMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"
                implicitHeight: 32
                implicitWidth: Math.max(80, sendLabel.implicitWidth + 32)
                radius: Appearance.rounding.small

                StyledText {
                    id: sendLabel

                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3Primary
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: qsTr("Send")
                }

                MArea {
                    id: sendMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.island.startTransfer()
                }
            }
        }
    }
}
