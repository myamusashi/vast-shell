import QtQuick
import QtQuick.Shapes
import QtQuick.Controls

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Slider {
    id: slider

    readonly property bool isWavy: Configs.mediaPlayer.sliderType === "Wavy"
    readonly property bool isWaveForm: Configs.mediaPlayer.sliderType === "WaveForm"

    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3SecondaryContainer

    // Shared
    property int separatorWidth: 8
    property bool enableWave: true
    property real waveTransition: 1.0

    // Wavy
    property int waveAmplitude: 3
    property real waveFrequency: 9.0
    property real waveAnimPhase: 0.0

    // WaveForm
    property real waveFreqBeach: 3.8    // waves across track (lower = wider)
    property real wavePow: 0.90   // crest width (<1 = wider crest)
    property real waveFloor: 0.36   // valley height as fraction of maxAmp
    property real waveRamp: 0.06   // distance from handle to reach full amplitude (normalised 0..1)
    property real waveMaxAmpRatio: 0.50   // maxAmp as fraction of track height
    property real wavePhaseBeach: 0.0

    Behavior on waveTransition {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    snapMode: Slider.NoSnap
    hoverEnabled: true

    onEnableWaveChanged: waveTransition = enableWave ? 1.0 : 0.0

    NumberAnimation on waveAnimPhase {
        running: slider.enableWave && slider.isWavy
        to: Math.PI * 2
        duration: 2000
        loops: Animation.Infinite
    }

    NumberAnimation on wavePhaseBeach {
        running: slider.enableWave && slider.isWaveForm
        to: Math.PI * 2
        duration: 3000
        loops: Animation.Infinite
    }

    background: Item {
        id: bg

        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 40

        readonly property real trackWidth: width
        readonly property real normalizedValue: slider.visualPosition

        Shape {
            id: wavyShape

            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            visible: slider.isWavy

            function buildWavePath() {
                const trackWidth = bg.trackWidth;
                const normalizedValue = bg.normalizedValue;
                const gapOffset = slider.separatorWidth / 2;
                const activeWidth = Math.max(0, trackWidth * normalizedValue - gapOffset);

                if (activeWidth <= 0)
                    return "M 0 0";

                const steps = Math.max(Math.floor(activeWidth / 3), 30);
                const effectiveAmp = slider.waveAmplitude * slider.waveTransition;
                let d = "M 0 " + (height / 2);

                for (let i = 1; i <= steps; i++) {
                    const progress = i / steps;
                    const currentProgress = (progress * activeWidth) / trackWidth;
                    const x = trackWidth * currentProgress;
                    const waveOffset = Math.sin(currentProgress * Math.PI * 2 * slider.waveFrequency + slider.waveAnimPhase) * effectiveAmp;
                    const y = height / 2 + waveOffset;
                    d += " L " + x + " " + y;
                }
                return d;
            }

            ShapePath {
                id: activeShapePath

                strokeColor: slider.activeColor
                strokeWidth: 4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg {
                    path: wavyShape.buildWavePath()
                }
            }
        }

        Shape {
            id: inactiveShape

            anchors.fill: parent

            property real inactiveStartPos: bg.normalizedValue + ((slider.separatorWidth / 2) / bg.trackWidth)
            property real inactiveWidth: bg.trackWidth * (1 - inactiveStartPos)

            preferredRendererType: Shape.CurveRenderer
            visible: slider.isWavy || (inactiveWidth > 0 && inactiveStartPos < 1)

            ShapePath {
                id: inactiveShapePath

                strokeColor: slider.inactiveColor
                strokeWidth: 4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                startX: bg.trackWidth * inactiveShape.inactiveStartPos
                startY: inactiveShape.height / 2

                PathLine {
                    x: bg.trackWidth
                    y: inactiveShape.height / 2
                }
            }
        }

        Shape {
            id: waveShape

            anchors.fill: parent

            // derived geometry
            readonly property real baseLine: height / 2
            readonly property real maxAmp: height * slider.waveMaxAmpRatio
            readonly property real activeEnd: Math.max(0, width * bg.normalizedValue - slider.separatorWidth / 2)
            readonly property real inactStart: Math.min(width, width * bg.normalizedValue + slider.separatorWidth / 2)

            // repaint triggers
            property real _pos: bg.normalizedValue
            property real _phase: slider.wavePhaseBeach
            property real _transition: slider.waveTransition

            // computed path arrays
            property var fillPath: []   // closed polygon → active fill
            property var strokePath: []   // top edge only  → active stroke
            property var inactPath: []   // flat line       → inactive track

            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            visible: slider.isWaveForm

            function buildPaths() {
                const W = width, H = height;
                if (W <= 0 || H <= 0)
                    return;
                const pos = bg.normalizedValue;
                const ph = slider.wavePhaseBeach;
                const aEnd = activeEnd;
                const iSt = inactStart;
                const bl = baseLine;
                const amp = maxAmp;
                const STEPS = Math.ceil(W / 1.2);
                const FREQ = slider.waveFreqBeach;
                const POW = slider.wavePow;
                const FLOOR = slider.waveFloor;
                const RAMP = slider.waveRamp;
                const TR = slider.waveTransition;

                function waveY(t) {
                    const raw = (1 + Math.sin(t * Math.PI * 2 * FREQ + ph)) / 2;
                    const shaped = Math.pow(raw, POW);
                    const dist = pos - t;
                    const env = Math.min(1, Math.max(0, dist / RAMP));
                    const smooth = env * env * (3 - 2 * env);
                    const floor = FLOOR * (1 - smooth * 0.5);
                    return (floor + (1 - floor) * shaped * smooth) * amp * TR;
                }

                // top edge, x = 0 → activeEnd
                const top = [];
                if (aEnd > 0) {
                    for (let i = 0; i <= STEPS; i++) {
                        const px = (i / STEPS) * aEnd;
                        top.push(Qt.point(px, bl - waveY(px / W)));
                    }
                }

                // fill polygon, close again to baseline
                const fill = top.slice();
                if (fill.length) {
                    fill.push(Qt.point(aEnd, bl));
                    fill.push(Qt.point(0, bl));
                }

                const inact = iSt < W ? [Qt.point(iSt, bl), Qt.point(W, bl)] : [];

                // assign triggers property change → Shape redraw otomatis
                fillPath = fill;
                strokePath = top;
                inactPath = inact;
            }

            on_PosChanged: buildPaths()
            on_PhaseChanged: buildPaths()
            on_TransitionChanged: buildPaths()
            onWidthChanged: buildPaths()
            onHeightChanged: buildPaths()
            onVisibleChanged: if (visible)
                buildPaths()

            // active fill
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0
                    y1: waveShape.baseLine - waveShape.maxAmp
                    x2: 0
                    y2: waveShape.baseLine
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(slider.activeColor.r, slider.activeColor.g, slider.activeColor.b, 0.90)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(slider.activeColor.r, slider.activeColor.g, slider.activeColor.b, 0.68)
                    }
                }
                PathPolyline {
                    path: waveShape.fillPath
                }
            }

            // active top stroke
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(slider.activeColor.r, slider.activeColor.g, slider.activeColor.b, 1.0)
                strokeWidth: 1.8
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline {
                    path: waveShape.strokePath
                }
            }

            // active baseLine stroke
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(slider.activeColor.r, slider.activeColor.g, slider.activeColor.b, 0.85)
                strokeWidth: 2.5
                capStyle: ShapePath.RoundCap
                PathPolyline {
                    path: waveShape.strokePath.length > 0 ? [Qt.point(0, waveShape.baseLine), Qt.point(waveShape.activeEnd, waveShape.baseLine)] : []
                }
            }

            // inactive flat line
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(slider.inactiveColor.r, slider.inactiveColor.g, slider.inactiveColor.b, 0.55)
                strokeWidth: 2.5
                capStyle: ShapePath.RoundCap
                PathPolyline {
                    path: waveShape.inactPath
                }
            }
        }
    }

    handle: Item {
        id: handleRoot

        x: slider.leftPadding + slider.visualPosition * slider.availableWidth - implicitWidth / 2
        y: slider.topPadding + slider.availableHeight / 2 - implicitHeight / 2
        implicitWidth: 22
        implicitHeight: 40

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 20
            radius: 3
            color: slider.activeColor
            visible: slider.isWavy
            opacity: slider.hovered ? 1 : 0
            scale: slider.pressed ? 1.3 : 1

            Behavior on scale {
                NAnim {}
            }
            Behavior on opacity {
                NAnim {}
            }
        }

        Rectangle {
            id: waveformHandle

            anchors.centerIn: parent
            visible: slider.isWaveForm
            width: 6
            height: 20
            radius: 3
            color: slider.activeColor
        }
    }
}
