import QtQuick
import Quickshell
import M3Shapes

import qs.Services

Item {
    id: root

    property bool contained: true
    property color containedIndicatorColor: Colours.m3Colors.m3OnPrimaryContainer
    property color containerColor: Colours.m3Colors.m3PrimaryContainer
    property real dampingRatio: 0.6
    property real globalRotation: 0
    property real globalRotationDuration: 4666
    property color indicatorColor: Colours.m3Colors.m3Primary
    readonly property real indicatorScale: 38 / 48
    property real lastFrameMs: 0
    property real morphInterval: 650
    property real morphRotation: 0
    property real rotationStart: 0
    property real rotationStep: 90
    property real rotationTarget: 90
    property int shapeIndex: 0
    readonly property var shapeSequence: [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval]
    readonly property real springDuration: {
        const wn = Math.sqrt(stiffness);
        const r = -dampingRatio * wn;
        const c = 1 / Math.sqrt(1 - dampingRatio * dampingRatio);
        return Math.log(visibilityThreshold / c) / r;
    }
    readonly property real springMaxVelocity: {
        const wn = Math.sqrt(stiffness);
        const factor = Math.exp(-dampingRatio * Math.acos(dampingRatio) / Math.sqrt(1 - dampingRatio * dampingRatio));
        return wn * factor;
    }
    property bool springSettled: true
    property bool status: false
    property real stiffness: 200
    property real visibilityThreshold: 0.1

    function spring(t: real): var {
        const wn = Math.sqrt(stiffness);
        const za = dampingRatio * wn;

        const wd = wn * Math.sqrt(1 - dampingRatio * dampingRatio);
        const r = za / wd;
        const pos = 1 - Math.exp(-za * t) * (Math.cos(wd * t) + r * Math.sin(wd * t));
        const vel = Math.exp(-za * t) * (wn * wn / wd) * Math.sin(wd * t);

        return [pos, vel];
    }

    height: implicitHeight
    implicitHeight: 48
    implicitWidth: 48
    scale: status ? 1 : 0
    visible: status
    width: implicitWidth

    Behavior on scale {
        SpringAnimation {
            damping: 0.3
            epsilon: 0.1
            spring: 5
        }
    }

    onStatusChanged: {
        if (status)
            lastFrameMs = 0;
    }

    MaterialShape {
        anchors.fill: parent
        animationDuration: 0
        color: root.containerColor
        shape: MaterialShape.Circle
        visible: root.contained
    }
    MaterialShape {
        id: indicator

        anchors.centerIn: parent
        color: root.contained ? root.containedIndicatorColor : root.indicatorColor
        fromShape: root.shapeSequence[root.shapeIndex]
        height: root.height * root.indicatorScale
        morphProgress: 1
        toShape: root.shapeSequence[root.shapeIndex]
        width: root.width * root.indicatorScale
    }
    ElapsedTimer {
        id: timer
    }
    FrameAnimation {
        running: root.status

        onTriggered: {
            const now = Date.now();
            const delta = root.lastFrameMs > 0 ? Math.min(now - root.lastFrameMs, 50) : 16.7;
            root.lastFrameMs = now;
            root.globalRotation = (root.globalRotation + 360 * delta / root.globalRotationDuration) % 360;

            if (!root.springSettled) {
                const t = timer.elapsed();

                if (t >= root.springDuration) {
                    root.springSettled = true;
                    indicator.morphProgress = 1;
                    root.morphRotation = root.rotationTarget;
                    indicator.scale = 1;
                } else {
                    const [pos, vel] = root.spring(t);
                    indicator.morphProgress = Math.min(1, pos);
                    root.morphRotation = root.rotationStart + pos * (root.rotationTarget - root.rotationStart);
                    indicator.scale = 1 + vel * 0.14 / root.springMaxVelocity;
                }
            }
            indicator.rotation = root.morphRotation + root.globalRotation;
        }
    }
    Timer {
        id: animTimer

        interval: root.morphInterval
        repeat: root.status
        running: root.status
        triggeredOnStart: true

        onTriggered: {
            const nextIndex = (root.shapeIndex + 1) % root.shapeSequence.length;

            indicator.fromShape = root.shapeSequence[root.shapeIndex];
            indicator.toShape = root.shapeSequence[nextIndex];
            indicator.morphProgress = 0;

            root.shapeIndex = nextIndex;
            root.rotationStart = root.morphRotation;
            root.rotationTarget = root.morphRotation + root.rotationStep;
            root.springSettled = false;
            timer.restart();
        }
    }
}
