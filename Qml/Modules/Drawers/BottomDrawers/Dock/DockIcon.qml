pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property string entryId
    required property var    entry
    required property var    toplevel

    readonly property bool   isFocusedToplevel: toplevel !== null && (toplevel.wayland?.activated === true || (GlobalStates.isShellKeyboardGrabActive && toplevel.address === Hypr.lastActiveToplevelAddress))
    readonly property bool   showsIndicator: toplevel !== null || (isPinned && entry !== null && DockServices.runningEntryIds.includes(entryId))

    property bool            draggable: false
    property bool            dragging: false
    property bool            hovered: false
    property real            iconSlot: 44
    property bool            isPinned: false

    signal                   activated
    signal                   contextMenuRequested(real anchorX, real anchorY)
    signal                   dragEnded
    signal                   dragMoved(real deltaX)
    signal                   dragStarted
    signal                   hoverEntered
    signal                   hoverExited

    implicitHeight: iconSlot + Appearance.spacing.small * 2
    implicitWidth: iconSlot + Appearance.spacing.small * 2
    height: implicitHeight
    width: implicitWidth
    z: dragging ? 10 : 0
    scale: dragging ? 1.08 : 1.0
    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    StyledRect {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.small
        color: "transparent"
        radius: Appearance.rounding.normal

        IconImage {
            anchors.centerIn: parent
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
        property bool dragActive: false
        property real pressParentX: 0
        property bool suppressNextClick: false

        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        layerRadius: Appearance.rounding.normal
        onPressed: mouse => {
            pressParentX      = root.mapToItem(root.parent, mouse.x, 0).x;
            dragActive        = false;
            suppressNextClick = false;
        }
        onPositionChanged: mouse => {
            if (!root.draggable || !pressed)
                return;

            const currentParentX = root.mapToItem(root.parent, mouse.x, 0).x;
            const deltaX         = currentParentX - pressParentX;
            if (!dragActive && Math.abs(deltaX) >= Qt.styleHints.startDragDistance) { // qmllint disable
                dragActive    = true;
                root.dragging = true;
                root.dragStarted();
            }

            if (dragActive)
                root.dragMoved(deltaX);
        }
        onReleased: {
            if (!dragActive)
                return;

            suppressNextClick = true;
            dragActive        = false;
            root.dragging     = false;
            root.dragEnded();
        }
        onCanceled: {
            if (!dragActive)
                return;

            dragActive    = false;
            root.dragging = false;
            root.dragEnded();
        }
        onClicked: {
            if (suppressNextClick) {
                suppressNextClick = false;
                return;
            }

            root.activated();
        }
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
        enabled: root.entry !== null && !root.dragging
        onClicked: mouse => {
            const point = root.mapToItem(null, mouse.x, 0);
            root.contextMenuRequested(point.x, point.y);
        }
    }
}
