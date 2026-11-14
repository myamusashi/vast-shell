import QtQuick
import Quickshell

Item {
    id: root

    required property color  color
    required property int    edge

    readonly property real   bodyInsetX: contentItem.x
    readonly property real   edgeMode: edge === Qt.BottomEdge ? 0 : edge === Qt.TopEdge ? 1 : edge === Qt.RightEdge ? 2 : 3
    readonly property string edgeName: edge === Qt.TopEdge ? "top" : edge === Qt.BottomEdge ? "bottom" : edge === Qt.LeftEdge ? "left" : "right"
    readonly property bool   isFlushToEnd: isHorizontalEdge ? !!(alignment & Qt.AlignRight) : !!(alignment & Qt.AlignBottom)
    readonly property bool   isFlushToStart: isHorizontalEdge ? !!(alignment & Qt.AlignLeft) : !!(alignment & Qt.AlignTop)
    readonly property bool   isHorizontalEdge: edge === Qt.TopEdge || edge === Qt.BottomEdge
    readonly property bool   isReflectedEdge: edge === Qt.TopEdge || edge === Qt.RightEdge
    readonly property real   parentBottomInset: parent?.bottomInset ?? 0 // qmllint disable missing-property
    readonly property real   parentHoleHeight: parent?.holeHeight ?? (parent ? parent.height : 0) // qmllint disable missing-property
    readonly property real   parentHoleWidth: parent?.holeWidth ?? (parent ? parent.width : 0) // qmllint disable missing-property
    readonly property real   parentLeftInset: parent?.leftInset ?? 0 // qmllint disable missing-property
    readonly property real   parentRightInset: parent?.rightInset ?? 0 // qmllint disable missing-property
    readonly property real   parentTopInset: parent?.topInset ?? 0 // qmllint disable missing-property

    property int             alignment: 0  // 0 = centered; Qt.AlignLeft/Right (top/bottom edges), Qt.AlignTop/Bottom (left/right edges)
    property real            animatedDepth: open ? depth : 0
    property bool            animateDepth: true
    property int             animationDuration: 300
    property list<real>      animationEasingCurve: []
    property int             animationEasingType: Easing.OutCubic
    property real            attachedFilletRadius: filletRadius
    property real            borderOverlap: 1
    property real            bottomMargin: 0
    property bool            clipContent: true
    default property alias   content: contentItem.data
    property real            cornerRadius: 30
    property real            depth: 300
    property real            edgeOffset: 0
    property real            filletRadius: 40
    property real            length: 400
    property bool            open: false
    property real            xOffset: 0
    property real            yOffset: 0

    height: isHorizontalEdge ? metrics.acrossEdgeExtent : metrics.alongEdgeExtent
    visible: metrics.snappedDepth > 0
    width: isHorizontalEdge ? metrics.alongEdgeExtent : metrics.acrossEdgeExtent
    x: Math.round(isHorizontalEdge ? parentLeftInset + (isFlushToStart ? 0 : isFlushToEnd ? parentHoleWidth - width : (parentHoleWidth - width) / 2) : (edge === Qt.LeftEdge ? parentLeftInset + edgeOffset : parent.width - parentRightInset - width - edgeOffset)) + xOffset
    y: Math.round(isHorizontalEdge ? (edge === Qt.TopEdge ? parentTopInset + edgeOffset : parent.height - parentBottomInset - height - edgeOffset) : parentTopInset + (isFlushToStart ? 0 : isFlushToEnd ? parentHoleHeight - height - bottomMargin : (parentHoleHeight - height) / 2)) + yOffset
    Behavior on animatedDepth {
        enabled: root.animateDepth

        NumberAnimation {
            duration: root.animationDuration
            easing.bezierCurve: root.animationEasingCurve
            easing.type: root.animationEasingCurve.length > 0 ? Easing.BezierSpline : root.animationEasingType
        }
    }

    Scope {
        id: metrics

        readonly property real acrossEdgeExtent: snappedDepth + freeSidePadding
        readonly property real activeAttachedFilletRadius: Math.min(root.attachedFilletRadius, snappedDepth / 2)
        readonly property real activeCornerRadius: Math.min(root.cornerRadius, snappedLength / 2, snappedDepth / 2)
        readonly property real activeFilletRadius: Math.min(root.filletRadius, snappedDepth / 2)
        readonly property real alongEdgeExtent: snappedLength + startPadding + endPadding
        readonly property real endPadding: root.isFlushToEnd ? 0 : root.filletRadius
        readonly property real freeSidePadding: (root.isFlushToStart || root.isFlushToEnd) ? root.filletRadius : 0
        readonly property real snappedDepth: Math.round(root.animatedDepth)
        readonly property real snappedLength: Math.round(root.length)

        // bounds include the fillet tips so Region { item: drawer } covers everything painted
        readonly property real startPadding: root.isFlushToStart ? 0 : root.filletRadius
    }

    DrawerShape {
        attachedFilletRadius: metrics.activeAttachedFilletRadius
        borderOverlap: root.borderOverlap
        color: root.color
        cornerRadius: metrics.activeCornerRadius
        drawerDepth: metrics.snappedDepth
        drawerLength: metrics.snappedLength
        edgeMode: root.edgeMode
        filletRadius: metrics.activeFilletRadius
        freeSidePadding: metrics.freeSidePadding
        isFlushToEnd: root.isFlushToEnd
        isFlushToStart: root.isFlushToStart
        startPadding: metrics.startPadding
    }

    Item {
        id: contentItem

        clip: root.clipContent
        height: root.isHorizontalEdge ? metrics.snappedDepth : metrics.snappedLength
        width: root.isHorizontalEdge ? metrics.snappedLength : metrics.snappedDepth
        x: root.isHorizontalEdge ? metrics.startPadding : (root.edge === Qt.LeftEdge ? 0 : metrics.freeSidePadding)
        y: root.isHorizontalEdge ? (root.edge === Qt.TopEdge ? 0 : metrics.freeSidePadding) : metrics.startPadding
    }
}
