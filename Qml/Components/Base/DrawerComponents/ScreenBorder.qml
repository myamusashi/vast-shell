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
    property real                dockHeight: 0
    property bool                enableOuterBorder: false
    property alias               innerRadius: frame.innerRadius
    property bool                isBarOpen: false
    property bool                isDockVisible: false
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
        dockHeight: root.dockHeight
        color: root.color
        enableOuterBorder: root.enableOuterBorder
        isBarOpen: root.isBarOpen
        isDockVisible: root.isDockVisible
        isFocusedMonitor: root.isFocusedMonitor
        outerBorderSize: root.outerBorderSize
        window: root.window
    }

    Item {
        id: topBorderArea

        height: frame.topThickness
        visible: height > 0 && width > 0
        width: frame.holeWidth
        x: frame.leftThickness
    }

    Item {
        id: bottomBorderArea

        height: frame.bottomThickness
        visible: height > 0 && width > 0
        width: frame.holeWidth
        x: frame.leftThickness
        y: root.height - height
    }

    Item {
        id: leftBorderArea

        height: root.height
        visible: height > 0 && width > 0
        width: frame.leftThickness
    }

    Item {
        id: rightBorderArea

        height: root.height
        visible: height > 0 && width > 0
        width: frame.rightThickness
        x: root.width - width
    }

    Item {
        id: topLeftCornerArea

        height: root.cornerAreaSize
        visible: root.cornerAreaSize > 0
        width: root.cornerAreaSize
        x: frame.leftThickness
        y: frame.topThickness
    }

    Item {
        id: topRightCornerArea

        height: root.cornerAreaSize
        visible: root.cornerAreaSize > 0
        width: root.cornerAreaSize
        x: root.width - frame.rightThickness - root.cornerAreaSize
        y: frame.topThickness
    }

    Item {
        id: bottomLeftCornerArea

        height: root.cornerAreaSize
        visible: root.cornerAreaSize > 0
        width: root.cornerAreaSize
        x: frame.leftThickness
        y: root.height - frame.bottomThickness - root.cornerAreaSize
    }

    Item {
        id: bottomRightCornerArea

        height: root.cornerAreaSize
        visible: root.cornerAreaSize > 0
        width: root.cornerAreaSize
        x: root.width - frame.rightThickness - root.cornerAreaSize
        y: root.height - frame.bottomThickness - root.cornerAreaSize
    }

    // Declared last so drawers draw above the frame

    Item {
        id: holeItem

        readonly property real bottomInset: frame.bottomThickness
        readonly property real holeHeight: frame.holeHeight
        readonly property real holeWidth: frame.holeWidth
        readonly property real leftInset: frame.leftThickness
        readonly property real rightInset: frame.rightThickness
        readonly property real topInset: frame.topThickness

        anchors.fill: parent
    }
}
