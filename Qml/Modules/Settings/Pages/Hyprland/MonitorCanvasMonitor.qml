pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

Rectangle {
    id: root

    // Logical-space rect from MonitorServices.rectForKey; positions update
    // reactively from the draft while dragging (no delegate rebuilds).
    required property string modelData

    readonly property bool   dragActive: dragArea.pressed
    readonly property var    rectData: MonitorServices.rectForKey(modelData)

    property bool            draggable: false
    property real            originX: 0
    property real            originY: 0
    property real            pxPerLogical: 1
    property real            snapThreshold: 8

    signal                   dragStateChanged(bool active)

    function                 finalizePosition(): void {
        // Re-run snap and overlap resolution on the final position so a
        // gesture that was interrupted mid-drag can never store an
        // overlapping layout (Hyprland refuses to register those).
        const snapped = MonitorServices.snappedPosition(root.modelData, root.rectData.x, root.rectData.y, root.snapThreshold);
        MonitorServices.setField(root.modelData, "x", snapped.x);
        MonitorServices.setField(root.modelData, "y", snapped.y);
    }

    visible: rectData !== null
    x: rectData === null ? 0 : originX + rectData.x * pxPerLogical
    y: rectData === null ? 0 : originY + rectData.y * pxPerLogical
    width: rectData === null ? 0 : rectData.width * pxPerLogical
    height: rectData === null ? 0 : rectData.height * pxPerLogical
    color: dragActive ? Colours.m3Colors.m3SecondaryContainer : Colours.m3Colors.m3PrimaryContainer
    radius: Appearance.rounding.small
    border.color: Colours.m3Colors.m3Primary
    border.width: dragActive ? 2 : 1
    onDragActiveChanged: dragStateChanged(dragActive)
    Component.onDestruction: {
        if (dragActive)
            dragStateChanged(false);
    }

    StyledText {
        anchors.centerIn: parent
        color: Colours.m3Colors.m3OnSurface
        elide: Text.ElideRight
        font.pixelSize: Appearance.fonts.size.small
        horizontalAlignment: Text.AlignHCenter
        text: root.rectData?.label ?? ""
        visible: root.height > 40
        width: parent.width - 8
    }

    Rectangle {

        anchors {
            bottom: parent.top
            bottomMargin: 6
            horizontalCenter: parent.horizontalCenter
        }

        color: Colours.m3Colors.m3InverseSurface
        implicitHeight: coordText.implicitHeight + 6
        implicitWidth: coordText.implicitWidth + 12
        radius: Appearance.rounding.small
        visible: root.dragActive

        StyledText {
            id: coordText

            anchors.centerIn: parent
            color: Colours.m3Colors.m3InverseOnSurface
            font.pixelSize: Appearance.fonts.size.small
            text: root.rectData === null ? "" : `${Math.round(root.rectData.x)}x${Math.round(root.rectData.y)}`
        }
    }

    MouseArea {
        id: dragArea

        property real grabOffsetX: 0
        property real grabOffsetY: 0

        anchors.fill: parent
        cursorShape: Qt.SizeAllCursor
        enabled: root.draggable && root.rectData !== null
        // Keep the grab on the monitor rectangle: without this the page Flickable
        // steals vertical drags and scrolls the settings page instead.
        preventStealing: true
        onPressed: mouse => {
            grabOffsetX = mouse.x / root.pxPerLogical;
            grabOffsetY = mouse.y / root.pxPerLogical;
            root.forceActiveFocus();
        }
        onPositionChanged: mouse => {
            const rawX    = (root.x + mouse.x - root.originX) / root.pxPerLogical - grabOffsetX;
            const rawY    = (root.y + mouse.y - root.originY) / root.pxPerLogical - grabOffsetY;
            const snapped = MonitorServices.snappedPosition(root.modelData, rawX, rawY, root.snapThreshold);
            MonitorServices.setField(root.modelData, "x", snapped.x);
            MonitorServices.setField(root.modelData, "y", snapped.y);
        }
        onReleased: root.finalizePosition()
        onCanceled: root.finalizePosition()
    }
}
