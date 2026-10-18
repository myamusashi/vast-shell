pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property string entryId
    required property var    entry
    required property var    toplevel

    property bool            hovered: false
    property real            iconSlot: 44
    property bool            isPinned: false
    property ShellScreen     screen: null

    signal                   activated
    signal                   hoverEntered
    signal                   hoverExited

    implicitHeight: root.iconSlot + Appearance.spacing.small * 2
    implicitWidth: root.iconSlot + Appearance.spacing.small * 2
    height: implicitHeight
    width: implicitWidth

    StyledRect {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.small
        color: "transparent"
        radius: Appearance.rounding.normal

        IconImage {
            anchors.centerIn: parent
            asynchronous: true
            backer.cache: true
            implicitSize: root.iconSlot
            source: Quickshell.iconPath(root.entry?.icon ?? "", "image-missing")
        }
    }

    StyledRect {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: Colours.m3Colors.m3Primary
        height: 4
        radius: 2
        visible: root.isPinned && root.entry !== null && DockServices.runningEntryIds.includes(root.entryId)
        width: 4
    }

    MArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        layerRadius: Appearance.rounding.normal
        onClicked: root.activated()
    }

    HoverHandler {
        blocking: false
        onHoveredChanged: {
            root.hovered = hovered;
            if (hovered)
                root.hoverEntered();
            else
                root.hoverExited();
        }
    }

    MouseArea {
        acceptedButtons: Qt.RightButton
        anchors.fill: parent
        enabled: root.entry !== null
        onClicked: mouse => {
            const point = root.mapToItem(null, mouse.x, mouse.y);
            dockContextMenu.openAt(point.x, point.y, root.entry, root.toplevel);
        }
    }

    DockContextMenu {
        id: dockContextMenu

        screen: root.screen
    }
}
