pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property string entryId
    required property var    entry
    required property var    toplevel

    readonly property var    entryToplevels: isPinned ? DockServices.scopedToplevelsForEntry(entryId) : (toplevel !== null ? [toplevel] : [])
    readonly property bool   hasFocusedToplevel: {
        const focusedAddress = DockServices.focusedToplevelAddress;
        for (const item of entryToplevels) {
            if (item !== null && item !== undefined && (item.wayland?.activated === true || (focusedAddress !== "" && item.address === focusedAddress)))
                return true;
        }
        return false;
    }
    readonly property int    runningCount: entryToplevels.length
    readonly property bool   showsDots: showsIndicator && !showsNumberBadge
    readonly property bool   showsIndicator: runningCount > 0
    readonly property bool   showsNumberBadge: isPinned && runningCount > 3

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

    Row {
        id: dotIndicatorRow

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        visible: root.showsDots

        Repeater {
            model: root.showsDots ? root.entryToplevels : []
            delegate: StyledRect {
                required property var  modelData

                readonly property bool isFocused: modelData !== null && modelData !== undefined && (modelData.wayland?.activated === true || (DockServices.focusedToplevelAddress !== "" && modelData.address === DockServices.focusedToplevelAddress))

                color: isFocused ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                height: 4
                radius: 2
                width: isFocused ? 16 : 4
                Behavior on width {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
        }
    }

    StyledRect {
        id: countBadge

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        border.color: root.hasFocusedToplevel ? "transparent" : Colours.m3Colors.m3OutlineVariant
        border.width: root.hasFocusedToplevel ? 0 : 1
        color: root.hasFocusedToplevel ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3SurfaceContainerHighest
        height: 14
        radius: Appearance.rounding.full
        visible: root.showsNumberBadge
        width: Math.max(16, countBadgeText.implicitWidth + 8)

        StyledText {
            id: countBadgeText

            anchors.centerIn: parent
            color: root.hasFocusedToplevel ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
            font.pixelSize: Math.max(9, Math.round(Appearance.fonts.size.small * 0.78))
            font.weight: Font.DemiBold
            text: String(root.runningCount)
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

    Tooltip {
        anchorItem: root
        enabled: (!root.showsIndicator || root.entryId === "") && !root.dragging
        position: Edges.Top
        text: root.entry?.name || root.toplevel?.lastIpcObject?.title || ""
    }
}
