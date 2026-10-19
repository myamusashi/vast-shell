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

    readonly property bool   isFocusedToplevel: toplevel !== null && toplevel.wayland?.activated === true
    readonly property bool   showsIndicator: toplevel !== null || (isPinned && entry !== null && DockServices.runningEntryIds.includes(entryId))

    property bool            hovered: false
    property real            iconSlot: 44
    property bool            isPinned: false
    property ShellScreen     screen: null

    signal                   activated
    signal                   hoverEntered
    signal                   hoverExited

    implicitHeight: iconSlot + Appearance.spacing.small * 2
    implicitWidth: iconSlot + Appearance.spacing.small * 2
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
        color: root.isFocusedToplevel || root.toplevel === null ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
        height: 4
        radius: 2
        visible: root.showsIndicator
        width: root.isFocusedToplevel ? 16 : 4
        Behavior on width {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
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
            const point = root.mapToItem(null, mouse.x, 0);
            dockContextMenu.openAt(point.x, point.y, root.entry, root.toplevel);
        }
    }

    DockContextMenu {
        id: dockContextMenu

        screen: root.screen
    }
}
