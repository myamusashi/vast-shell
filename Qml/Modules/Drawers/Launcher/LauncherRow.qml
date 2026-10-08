pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ItemDelegate {
    id: root

    required property int index
    required property var modelData

    signal                rowClicked(var row)
    signal                rowHovered(int rowIndex)

    implicitHeight: 50
    implicitWidth: 300
    background: Item {}
    contentItem: RowLayout {
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Appearance.margin.normal
            clip: true
            implicitHeight: 40
            implicitWidth: 40

            IconImage {
                anchors.centerIn: parent
                asynchronous: true
                backer.cache: true
                implicitSize: parent.height
                source: Quickshell.iconPath(root.modelData.entry.icon, "image-missing")
            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.rightMargin: Appearance.margin.normal
            spacing: 2

            HighlightText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                fullText: root.modelData.name || ""
                searchText: LauncherServices.rowSearchText
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.small
                text: root.modelData.comment ?? ""
                visible: text !== ""
            }
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.rowClicked(root.modelData)
        onEntered: root.rowHovered(root.index)
    }
}
