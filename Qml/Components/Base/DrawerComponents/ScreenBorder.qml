pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property color      color
    required property bool       isFocusedMonitor

    readonly property list<Item> borderMaskItems: [topBorderArea, bottomBorderArea, leftBorderArea, rightBorderArea, topLeftCornerArea, topRightCornerArea, bottomLeftCornerArea, bottomRightCornerArea]
    readonly property real       cornerAreaSize: frame.effectiveInnerRadius

    property real                barHeight: 40
    property alias               bottomThickness: frame.bottomThickness
    default property alias       content: holeItem.data
    property bool                enableOuterBorder: false
    property alias               innerRadius: frame.innerRadius
    property bool                isBarOpen: false
    property alias               leftThickness: frame.leftThickness
    property real                outerBorderSize: 0
    property alias               rightThickness: frame.rightThickness
    property alias               topThickness: frame.topThickness
    property alias               window: frame.window

    function                     collectMaskItems() {
        const items        = borderMaskItems.slice();
        const holeChildren = holeItem.children;
        for (let index = 0; index < holeChildren.length; index++)
            items.push(holeChildren[index]);
        return items;
    }

    anchors.fill: parent

    BorderFrame {
        id: frame

        anchors.fill: parent
        barHeight: root.barHeight
        color: root.color
        enableOuterBorder: root.enableOuterBorder
        isBarOpen: root.isBarOpen
        isFocusedMonitor: root.isFocusedMonitor
        outerBorderSize: root.outerBorderSize
        window: root.window
    }

    Item {
        id: topBorderArea

        height: frame.topThickness
        width: root.width
    }

    Item {
        id: bottomBorderArea

        height: frame.bottomThickness
        width: root.width
        y: root.height - height
    }

    Item {
        id: leftBorderArea

        height: root.height - frame.topThickness - frame.bottomThickness
        width: frame.leftThickness
        y: frame.topThickness
    }

    Item {
        id: rightBorderArea

        height: root.height - frame.topThickness - frame.bottomThickness
        width: frame.rightThickness
        x: root.width - width
        y: frame.topThickness
    }

    Item {
        id: topLeftCornerArea

        height: root.cornerAreaSize
        width: root.cornerAreaSize
        x: frame.leftThickness
        y: frame.topThickness
    }

    Item {
        id: topRightCornerArea

        height: root.cornerAreaSize
        width: root.cornerAreaSize
        x: root.width - frame.rightThickness - root.cornerAreaSize
        y: frame.topThickness
    }

    Item {
        id: bottomLeftCornerArea

        height: root.cornerAreaSize
        width: root.cornerAreaSize
        x: frame.leftThickness
        y: root.height - frame.bottomThickness - root.cornerAreaSize
    }

    Item {
        id: bottomRightCornerArea

        height: root.cornerAreaSize
        width: root.cornerAreaSize
        x: root.width - frame.rightThickness - root.cornerAreaSize
        y: root.height - frame.bottomThickness - root.cornerAreaSize
    }

    // Declared last so drawers draw above the frame

    Item {
        id: holeItem

        height: frame.holeHeight
        width: frame.holeWidth
        x: frame.leftThickness
        y: frame.topThickness
    }
}
