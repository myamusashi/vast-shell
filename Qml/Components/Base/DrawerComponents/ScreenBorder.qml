pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    anchors.fill: parent

    required property color color
    required property bool isFocusedMonitor

    property alias window: frame.window
    property alias topThickness: frame.topThickness
    property alias bottomThickness: frame.bottomThickness
    property alias leftThickness: frame.leftThickness
    property alias rightThickness: frame.rightThickness
    property alias innerRadius: frame.innerRadius

    property bool isBarOpen: false
    property real barHeight: 40
    property bool enableOuterBorder: false
    property real outerBorderSize: 0

    default property alias content: holeItem.data

    readonly property list<Item> borderMaskItems: [topBorderArea, bottomBorderArea, leftBorderArea, rightBorderArea, topLeftCornerArea, topRightCornerArea, bottomLeftCornerArea, bottomRightCornerArea]
    readonly property real cornerAreaSize: frame.effectiveInnerRadius

    function collectMaskItems() {
        const items = borderMaskItems.slice();
        const holeChildren = holeItem.children;
        for (let index = 0; index < holeChildren.length; index++)
            items.push(holeChildren[index]);
        return items;
    }

    BorderFrame {
        id: frame

        anchors.fill: parent
        color: root.color
        window: root.window
        isFocusedMonitor: root.isFocusedMonitor
        isBarOpen: root.isBarOpen
        barHeight: root.barHeight
        enableOuterBorder: root.enableOuterBorder
        outerBorderSize: root.outerBorderSize
    }

    Item {
        id: topBorderArea
        width: root.width
        height: frame.topThickness
    }
    Item {
        id: bottomBorderArea
        y: root.height - height
        width: root.width
        height: frame.bottomThickness
    }
    Item {
        id: leftBorderArea
        y: frame.topThickness
        width: frame.leftThickness
        height: root.height - frame.topThickness - frame.bottomThickness
    }
    Item {
        id: rightBorderArea
        x: root.width - width
        y: frame.topThickness
        width: frame.rightThickness
        height: root.height - frame.topThickness - frame.bottomThickness
    }

    Item {
        id: topLeftCornerArea
        x: frame.leftThickness
        y: frame.topThickness
        width: root.cornerAreaSize
        height: root.cornerAreaSize
    }
    Item {
        id: topRightCornerArea
        x: root.width - frame.rightThickness - root.cornerAreaSize
        y: frame.topThickness
        width: root.cornerAreaSize
        height: root.cornerAreaSize
    }
    Item {
        id: bottomLeftCornerArea
        x: frame.leftThickness
        y: root.height - frame.bottomThickness - root.cornerAreaSize
        width: root.cornerAreaSize
        height: root.cornerAreaSize
    }
    Item {
        id: bottomRightCornerArea
        x: root.width - frame.rightThickness - root.cornerAreaSize
        y: root.height - frame.bottomThickness - root.cornerAreaSize
        width: root.cornerAreaSize
        height: root.cornerAreaSize
    }

    // Declared last so drawers draw above the frame
    Item {
        id: holeItem
        x: frame.leftThickness
        y: frame.topThickness
        width: frame.holeWidth
        height: frame.holeHeight
    }
}
