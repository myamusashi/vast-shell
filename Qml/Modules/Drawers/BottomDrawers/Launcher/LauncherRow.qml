pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property string comment
    required property string icon
    required property int    index
    required property string itemId
    required property string name

    readonly property bool   isPinned: DockServices.pinnedIds.includes(root.itemId)

    signal                   rowClicked(int rowIndex)
    signal                   rowHovered(int rowIndex)

    implicitHeight: 50
    implicitWidth: 300

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.normal

        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Appearance.margin.normal
            clip: true
            implicitHeight: 40
            implicitWidth: 40

            IconImage {
                anchors.centerIn: parent
                backer.asynchronous: true
                backer.cache: true
                implicitSize: parent.height
                source: Quickshell.iconPath(root.icon, "image-missing")
            }
        }

        Column {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: Appearance.margin.normal
            spacing: 2

            HighlightText {
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                fullText: root.name
                searchText: LauncherServices.rowSearchText
                width: parent.width
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.small
                text: root.comment
                visible: text !== ""
                width: parent.width
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Appearance.margin.normal
            implicitHeight: 32
            implicitWidth: 32

            Icon {
                anchors.centerIn: parent
                color: root.isPinned ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
                icon: root.isPinned ? "keep" : "keep_off"
            }

            MArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                layerRadius: Appearance.rounding.normal
                z: 1
                onClicked: DockServices.togglePin(root.itemId)
            }
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.rowClicked(root.index)
        onEntered: root.rowHovered(root.index)
    }
}
