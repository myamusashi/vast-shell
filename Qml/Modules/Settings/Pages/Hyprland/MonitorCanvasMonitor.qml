pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

Rectangle {
    id: root

    required property string modelData

    readonly property bool   dragActive: dragArea.pressed
    readonly property var    rectData: MonitorServices.rectForKey(modelData)

    property bool            draggable: false
    property bool            isSelected: false
    property real            originX: 0
    property real            originY: 0
    property real            pxPerLogical: 1
    property real            snapThreshold: 8

    signal                   clicked
    signal                   dragStateChanged(bool active)

    function                 finalizePosition(): void {
        const snapped = MonitorServices.snappedPosition(root.modelData, root.rectData.x, root.rectData.y, root.snapThreshold);
        MonitorServices.setField(root.modelData, "x", snapped.x);
        MonitorServices.setField(root.modelData, "y", snapped.y);
    }

    visible: rectData !== null
    x: rectData === null ? 0 : originX + rectData.x * pxPerLogical
    y: rectData === null ? 0 : originY + rectData.y * pxPerLogical
    width: rectData === null ? 0 : rectData.width * pxPerLogical
    height: rectData === null ? 0 : rectData.height * pxPerLogical
    color: dragActive ? Colours.m3Colors.m3SecondaryContainer : (root.isSelected ? Colours.m3Colors.m3PrimaryContainer : Colours.m3Colors.m3SurfaceContainerHigh)
    radius: Appearance.rounding.small
    border.color: (root.isSelected || dragActive) ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Outline
    border.width: (root.isSelected || dragActive) ? 2 : 1
    onDragActiveChanged: dragStateChanged(dragActive)
    Component.onDestruction: {
        if (dragActive)
            dragStateChanged(false);
    }

    Column {
        anchors.centerIn: parent
        spacing: 2
        visible: root.height > 40
        width: parent.width - 8

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.small
            horizontalAlignment: Text.AlignHCenter
            text: root.rectData?.label ?? ""
            width: parent.width
        }

        StyledText {
            color: Colours.m3Colors.m3Primary
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.small
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Primary")
            visible: root.rectData?.primary === true && root.height > 64
            width: parent.width
        }
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
        cursorShape: root.draggable ? Qt.SizeAllCursor : Qt.PointingHandCursor
        enabled: root.rectData !== null
        preventStealing: true
        onPressed: mouse => {
            root.clicked();
            if (root.draggable) {
                grabOffsetX = mouse.x / root.pxPerLogical;
                grabOffsetY = mouse.y / root.pxPerLogical;
                root.forceActiveFocus();
            }
        }
        onPositionChanged: mouse => {
            if (!root.draggable)
                return;
            const rawX    = (root.x + mouse.x - root.originX) / root.pxPerLogical - grabOffsetX;
            const rawY    = (root.y + mouse.y - root.originY) / root.pxPerLogical - grabOffsetY;
            const snapped = MonitorServices.snappedPosition(root.modelData, rawX, rawY, root.snapThreshold);
            MonitorServices.setField(root.modelData, "x", snapped.x);
            MonitorServices.setField(root.modelData, "y", snapped.y);
        }
        onReleased: {
            if (root.draggable)
                root.finalizePosition();
        }
        onCanceled: {
            if (root.draggable)
                root.finalizePosition();
        }
    }

    Tooltip {
        anchorItem: root
        enabled: !root.dragActive && root.rectData !== null
        text: root.rectData ? `${root.rectData.label} (${Math.round(root.rectData.width)}×${Math.round(root.rectData.height)})${root.rectData.primary ? ` · ${qsTr("Primary")}` : ""}` : ""
    }
}
