pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property bool active
    readonly property int fileCount: island.droppedFiles.length
    readonly property real fileNameMaxWidth: active ? FileListMetrics.computeMaxWidth(island.droppedFiles, file => String(file).split("/").pop().length * 8, 300, 40) : 0
    required property var island
    readonly property real maxContentHeight: FileListMetrics.clampHeight(fileCount, 18, 4, 200)
    readonly property real visibleHeight: maxContentHeight

    implicitHeight: visibleHeight + 56
    implicitWidth: FileListMetrics.clampWidth(fileNameMaxWidth + 80, 220, Number.POSITIVE_INFINITY)

    StyledText {
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.normal
        font.weight: Font.DemiBold
        text: qsTr("%1 file(s)").arg(root.fileCount)
        visible: root.active

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 8
        }
    }
    Flickable {
        id: filesFlickable

        boundsBehavior: Flickable.StopAtBounds
        clip: true
        contentHeight: root.maxContentHeight
        contentWidth: width
        flickableDirection: Flickable.VerticalFlick
        height: root.visibleHeight
        visible: root.active

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        anchors {
            left: parent.left
            leftMargin: 8
            right: parent.right
            rightMargin: 12
            top: parent.top
            topMargin: 32
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
                    width: filesFlickable.width
                }
            }
        }
    }
    ExtendedFloatingButton {
        color: "transparent"
        implicitHeight: 28
        text: qsTr("Next")
        textColor: Colours.m3Colors.m3Primary
        visible: root.active

        onClicked: root.island.goToDeviceSelection()

        anchors {
            bottom: parent.bottom
            margins: Appearance.margin.small
            right: parent.right
        }
    }
}
