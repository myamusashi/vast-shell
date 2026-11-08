pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

Item {
    id: root

    readonly property real contentHeight: world.height * pxPerLogical
    readonly property real contentWidth: world.width * pxPerLogical
    readonly property real contentX: (width - contentWidth) / 2
    readonly property real contentY: (height - contentHeight) / 2
    readonly property var  liveWorld: computeWorld(rects)
    readonly property real originX: contentX - world.xMin * pxPerLogical
    readonly property real originY: contentY - world.yMin * pxPerLogical
    readonly property real pxPerLogical: (world.width <= 0 || world.height <= 0) ? 1 : Math.min(width / world.width, height / world.height, 1)
    readonly property var  rects: MonitorServices.drawableRects()
    readonly property real snapThreshold: 8 / pxPerLogical
    readonly property var  world: frozenWorld ?? liveWorld

    property int           activeDrags: 0
    property var           frozenWorld: null
    property string        rectKeyCache: ""
    property var           rectKeys: []
    property string        selectedKey: ""

    signal                 monitorSelected(string key)

    function               computeWorld(rects: var): var {
        let xMin = 0;
        let yMin = 0;
        let xMax = 0;
        let yMax = 0;
        for (const rect of rects) {
            xMin = Math.min(xMin, rect.x);
            yMin = Math.min(yMin, rect.y);
            xMax = Math.max(xMax, rect.x + rect.width);
            yMax = Math.max(yMax, rect.y + rect.height);
        }
        const margin = Math.max((xMax - xMin) * 0.1, (yMax - yMin) * 0.1, 200);
        return {
            height: (yMax - yMin) + 2 * margin,
            width: (xMax - xMin) + 2 * margin,
            xMin: xMin - margin,
            yMin: yMin - margin
        };
    }

    implicitHeight: 300
    onActiveDragsChanged: {
        if (activeDrags === 1)
            frozenWorld = liveWorld;
        else if (activeDrags === 0)
            frozenWorld = null;
    }
    onRectsChanged: {
        const joined = rects.map(rect => rect.key).join("\u0001");
        if (joined === rectKeyCache)
            return;
        rectKeyCache = joined;
        rectKeys     = rects.map(rect => rect.key);
    }

    Rectangle {
        anchors.fill: parent
        border.color: Colours.m3Colors.m3OutlineVariant
        color: Colours.m3Colors.m3Surface
        radius: Appearance.rounding.normal

        StyledText {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: root.rects.length === 0 ? qsTr("No enabled monitors detected.") : ""
        }
    }

    Repeater {
        model: root.rectKeys
        delegate: MonitorCanvasMonitor {
            draggable: root.rects.length > 1
            isSelected: modelData === root.selectedKey
            onClicked: root.monitorSelected(modelData)
            onDragStateChanged: active => root.activeDrags += active ? 1 : -1
            originX: root.originX
            originY: root.originY
            pxPerLogical: root.pxPerLogical
            snapThreshold: root.snapThreshold
        }
    }

    StyledText {

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: Appearance.margin.normal
        }

        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.small
        text: root.rects.length > 1 ? qsTr("Drag monitors to arrange them. Positions snap to edges and overlaps are prevented; coordinates are shown while dragging.") : qsTr("With a single enabled monitor its position stays managed by Hyprland.")
        visible: root.rects.length > 0
    }
}
