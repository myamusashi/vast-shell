import QtQuick

import qs.Core.Utils
import qs.Services

import "../Base"

Item {
    id: root

    readonly property real arcLen: 0.5 * Math.PI * effectiveRadius
    readonly property real bottomLen: Math.max(0, width - 2 * effectiveRadius)
    readonly property real effectiveRadius: Math.max(0, Math.min(radius, width / 2, height / 2))
    readonly property real leftLen: Math.max(0, height - 2 * effectiveRadius)
    readonly property real rightLen: Math.max(0, height - 2 * effectiveRadius)
    readonly property real seg1End: totalPerimeter > 0 ? topHalfLen / totalPerimeter : 0
    readonly property real seg2End: seg1End + (totalPerimeter > 0 ? arcLen / totalPerimeter : 0)
    readonly property real seg3End: seg2End + (totalPerimeter > 0 ? rightLen / totalPerimeter : 0)
    readonly property real seg4End: seg3End + (totalPerimeter > 0 ? arcLen / totalPerimeter : 0)
    readonly property real seg5End: seg4End + (totalPerimeter > 0 ? bottomLen / totalPerimeter : 0)
    readonly property real seg6End: seg5End + (totalPerimeter > 0 ? arcLen / totalPerimeter : 0)
    readonly property real seg7End: seg6End + (totalPerimeter > 0 ? leftLen / totalPerimeter : 0)
    readonly property real seg8End: seg7End + (totalPerimeter > 0 ? arcLen / totalPerimeter : 0)
    readonly property real topHalfLen: Math.max(0, width / 2 - effectiveRadius)
    readonly property real totalPerimeter: 2 * topHalfLen + rightLen + bottomLen + leftLen + 4 * arcLen

    property alias         animation: progressAnimation
    property alias         animationDuration: progressAnimation.duration
    property color         borderColor: Colours.m3Colors.m3Primary
    property real          borderWidth: 2.0
    property real          progress: 1.0
    property real          radius: source?.radius ?? 0
    property var           source: null

    function               segmentProgress(startPos: real, endPos: real): real {
        const span = endPos - startPos;
        if (span <= 0)
            return 0;
        return Math.max(0, Math.min(1, (root.progress - startPos) / span));
    }

    anchors.fill: parent
    visible: progress > 0

    // Segment 1: Top-right straight edge (top-center -> top-right corner)

    Rectangle {
        readonly property real localProgress: root.segmentProgress(0, root.seg1End)

        color: root.borderColor
        height: root.borderWidth
        visible: localProgress > 0 && root.topHalfLen > 0
        width: root.topHalfLen * localProgress
        x: root.width / 2
        y: 0
    }

    // Segment 2: Top-right corner arc

    CornerArc {
        cornerOffsetX: -root.effectiveRadius
        cornerOffsetY: 0
        localProgress: root.segmentProgress(root.seg1End, root.seg2End)
        startAngleDeg: -90
        x: root.width - root.effectiveRadius
        y: 0
    }

    // Segment 3: Right straight edge

    Rectangle {
        readonly property real localProgress: root.segmentProgress(root.seg2End, root.seg3End)

        color: root.borderColor
        height: root.rightLen * localProgress
        visible: localProgress > 0 && root.rightLen > 0
        width: root.borderWidth
        x: root.width - root.borderWidth
        y: root.effectiveRadius
    }

    // Segment 4: Bottom-right corner arc

    CornerArc {
        cornerOffsetX: -root.effectiveRadius
        cornerOffsetY: -root.effectiveRadius
        localProgress: root.segmentProgress(root.seg3End, root.seg4End)
        startAngleDeg: 0
        x: root.width - root.effectiveRadius
        y: root.height - root.effectiveRadius
    }

    // Segment 5: Bottom straight edge (right -> left)

    Rectangle {
        readonly property real localProgress: root.segmentProgress(root.seg4End, root.seg5End)

        color: root.borderColor
        height: root.borderWidth
        visible: localProgress > 0 && root.bottomLen > 0
        width: root.bottomLen * localProgress
        x: root.effectiveRadius + root.bottomLen * (1 - localProgress)
        y: root.height - root.borderWidth
    }

    // Segment 6: Bottom-left corner arc

    CornerArc {
        cornerOffsetX: 0
        cornerOffsetY: -root.effectiveRadius
        localProgress: root.segmentProgress(root.seg5End, root.seg6End)
        startAngleDeg: 90
        x: 0
        y: root.height - root.effectiveRadius
    }

    // Segment 7: Left straight edge (bottom -> top)

    Rectangle {
        readonly property real localProgress: root.segmentProgress(root.seg6End, root.seg7End)

        color: root.borderColor
        height: root.leftLen * localProgress
        visible: localProgress > 0 && root.leftLen > 0
        width: root.borderWidth
        x: 0
        y: root.effectiveRadius + root.leftLen * (1 - localProgress)
    }

    // Segment 8: Top-left corner arc

    CornerArc {
        cornerOffsetX: 0
        cornerOffsetY: 0
        localProgress: root.segmentProgress(root.seg7End, root.seg8End)
        startAngleDeg: 180
        x: 0
        y: 0
    }

    // Segment 9: Top-left straight edge (top-left corner -> top-center)

    Rectangle {
        readonly property real localProgress: root.segmentProgress(root.seg8End, 1.0)

        color: root.borderColor
        height: root.borderWidth
        visible: localProgress > 0 && root.topHalfLen > 0
        width: root.topHalfLen * localProgress
        x: root.effectiveRadius
        y: 0
    }

    NAnim {
        id: progressAnimation

        duration: 500
        from: 1.0
        property: "progress"
        target: root
        to: 0.0
    }

    component CornerArc: Item {
        id: arcRoot

        required property real cornerOffsetX
        required property real cornerOffsetY
        required property real localProgress
        required property real startAngleDeg

        clip: true
        height: root.effectiveRadius
        visible: localProgress > 0 && root.effectiveRadius > 0
        width: root.effectiveRadius

        ShaderEffect {
            property color    activeColor: root.borderColor
            property real     maxSweepDeg: 90
            property real     progress: arcRoot.localProgress
            property real     radius: Math.max(0, root.effectiveRadius - root.borderWidth * 0.5)
            property vector2d resolution: Qt.vector2d(width, height)
            property real     startAngleDeg: arcRoot.startAngleDeg
            property real     strokeWidth: root.borderWidth
            property color    trackColor: "transparent"

            blending: true
            fragmentShader: Paths.projectRoot + "/Assets/shaders/arcGauge.frag.qsb"
            height: root.effectiveRadius * 2
            width: root.effectiveRadius * 2
            x: arcRoot.cornerOffsetX
            y: arcRoot.cornerOffsetY
        }
    }
}
