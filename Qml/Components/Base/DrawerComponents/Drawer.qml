import QtQuick
import Quickshell

import "DrawerOutline.js" as OutlineBuilder

Item {
    id: root

    required property int edge            // Qt.TopEdge / BottomEdge / LeftEdge / RightEdge
    property int alignment: 0             // 0 = centered; Qt.AlignLeft/Right (top/bottom edges), Qt.AlignTop/Bottom (left/right edges)
    property bool open: false
    property real depth: 300
    property real length: 400
    property real cornerRadius: 30
    property real filletRadius: 40
    property real borderOverlap: 1
    required property color color
    property int animationDuration: 300
    property int animationEasingType: Easing.OutCubic
    property list<real> animationEasingCurve: []
    property bool clipContent: true
    property real edgeOffset: 0

    default property alias content: contentItem.data

    readonly property bool isHorizontalEdge: edge === Qt.TopEdge || edge === Qt.BottomEdge
    readonly property bool isFlushToStart: isHorizontalEdge ? !!(alignment & Qt.AlignLeft) : !!(alignment & Qt.AlignTop)
    readonly property bool isFlushToEnd: isHorizontalEdge ? !!(alignment & Qt.AlignRight) : !!(alignment & Qt.AlignBottom)
    readonly property bool isReflectedEdge: edge === Qt.TopEdge || edge === Qt.RightEdge
    readonly property string edgeName: edge === Qt.TopEdge ? "top" : edge === Qt.BottomEdge ? "bottom" : edge === Qt.LeftEdge ? "left" : "right"

    property real animatedDepth: open ? depth : 0
    Behavior on animatedDepth {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.animationEasingCurve.length > 0 ? Easing.BezierSpline : root.animationEasingType
            easing.bezierCurve: root.animationEasingCurve
        }
    }

    Scope {
        id: metrics

        // Whole pixels so edges never land between device pixels
        readonly property real snappedDepth: Math.round(root.animatedDepth)
        readonly property real snappedLength: Math.round(root.length)
        readonly property real activeFilletRadius: Math.min(root.filletRadius, snappedDepth / 2)
        readonly property real activeCornerRadius: Math.min(root.cornerRadius, snappedLength / 2, snappedDepth / 2)

        // bounds include the fillet tips so Region { item: drawer } covers everything painted
        readonly property real startPadding: root.isFlushToStart ? 0 : root.filletRadius
        readonly property real endPadding: root.isFlushToEnd ? 0 : root.filletRadius
        readonly property real freeSidePadding: (root.isFlushToStart || root.isFlushToEnd) ? root.filletRadius : 0
        readonly property real alongEdgeExtent: snappedLength + startPadding + endPadding
        readonly property real acrossEdgeExtent: snappedDepth + freeSidePadding
    }

    width: isHorizontalEdge ? metrics.alongEdgeExtent : metrics.acrossEdgeExtent
    height: isHorizontalEdge ? metrics.acrossEdgeExtent : metrics.alongEdgeExtent
    visible: metrics.snappedDepth > 0

    x: Math.round(isHorizontalEdge ? (isFlushToStart ? 0 : isFlushToEnd ? parent.width - width : (parent.width - width) / 2) : (edge === Qt.LeftEdge ? edgeOffset : parent.width - width - edgeOffset))
    y: Math.round(isHorizontalEdge ? (edge === Qt.TopEdge ? edgeOffset : parent.height - height - edgeOffset) : (isFlushToStart ? 0 : isFlushToEnd ? parent.height - height : (parent.height - height) / 2))

    readonly property string outlinePath: OutlineBuilder.buildOutline({
        edgeName: edgeName,
        snappedDepth: metrics.snappedDepth,
        snappedLength: metrics.snappedLength,
        activeFilletRadius: metrics.activeFilletRadius,
        activeCornerRadius: metrics.activeCornerRadius,
        borderOverlap: borderOverlap,
        isFlushToStart: isFlushToStart,
        isFlushToEnd: isFlushToEnd,
        isReflectedEdge: isReflectedEdge,
        startPadding: metrics.startPadding,
        freeSidePadding: metrics.freeSidePadding,
        acrossEdgeExtent: metrics.acrossEdgeExtent
    })

    DrawerShape {
        pathData: root.outlinePath
        color: root.color
    }

    // Body area only (excludes the fillet tips)
    Item {
        id: contentItem
        x: root.isHorizontalEdge ? metrics.startPadding : (root.edge === Qt.LeftEdge ? 0 : metrics.freeSidePadding)
        y: root.isHorizontalEdge ? (root.edge === Qt.TopEdge ? 0 : metrics.freeSidePadding) : metrics.startPadding
        width: root.isHorizontalEdge ? metrics.snappedLength : metrics.snappedDepth
        height: root.isHorizontalEdge ? metrics.snappedDepth : metrics.snappedLength
        clip: root.clipContent
    }
}
