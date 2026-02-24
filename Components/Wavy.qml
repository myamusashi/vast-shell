import QtQuick
import QtQuick.Shapes
import QtQuick.Controls

import qs.Components
import qs.Configs
import qs.Services

Slider {
    id: slider

    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3SecondaryContainer
    property int waveAmplitude: 3
    property real waveFrequency: 10
    property int separatorWidth: 8
    property int separatorHeight: 4
    property real waveAnimationPhase: 1
    property bool enableWave: true
    property real waveTransition: 1.0

    Behavior on waveTransition {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    snapMode: Slider.NoSnap
    hoverEnabled: true
    onEnableWaveChanged: waveTransition = enableWave ? 1.0 : 0.0

    NumberAnimation on waveAnimationPhase {
        running: slider.enableWave
        from: 0
        to: Math.PI * 2
        duration: 2000
        loops: Animation.Infinite
    }

    background: Item {
        id: bg

        readonly property real trackStartX: 0
        readonly property real trackEndX: width
        readonly property real trackWidth: trackEndX - trackStartX
        readonly property real normalizedValue: slider.visualPosition

        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: slider.availableWidth
        height: slider.height || 10

        // Active track
        Shape {
            id: wavyShape

            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            function buildWavePath() {
                var trackStartX = bg.trackStartX;
                var trackWidth = bg.trackWidth;
                var normalizedValue = bg.normalizedValue;
                var gapOffset = slider.separatorWidth / 2;
                var activeWidth = Math.max(0, trackWidth * normalizedValue - gapOffset);

                if (activeWidth <= 0)
                    return "M 0 0";

                var steps = Math.max(Math.floor(activeWidth / 3), 30);
                var effectiveAmplitude = slider.waveAmplitude * slider.waveTransition;
                var d = "M " + trackStartX + " " + (height / 2);

                for (var i = 1; i <= steps; i++) {
                    var progress = i / steps;
                    var currentProgress = (progress * activeWidth) / trackWidth;
                    var x = trackStartX + trackWidth * currentProgress;
                    var waveOffset = Math.sin(currentProgress * Math.PI * 2 * slider.waveFrequency + slider.waveAnimationPhase) * effectiveAmplitude;
                    var y = height / 2 + waveOffset;
                    d += " L " + x + " " + y;
                }

                return d;
            }

            ShapePath {
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

        // Inactive track
        Shape {
            id: inactiveShape

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            property real inactiveStartPos: bg.normalizedValue + ((slider.separatorWidth / 2) / bg.trackWidth)
            property real inactiveWidth: bg.trackWidth * (1 - inactiveStartPos)

            visible: inactiveWidth > 0 && inactiveStartPos < 1

            ShapePath {
                strokeColor: slider.inactiveColor
                strokeWidth: 4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                startX: bg.trackStartX + bg.trackWidth * inactiveShape.inactiveStartPos
                startY: inactiveShape.height / 2

                PathLine {
                    x: bg.trackStartX + bg.trackWidth
                    y: inactiveShape.height / 2
                }
            }
        }
    }

    handle: StyledRect {
        id: handleRect

        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        implicitWidth: 6
        implicitHeight: 20
        color: slider.activeColor
        opacity: slider.hovered ? 1 : 0
        scale: slider.pressed ? 1.3 : 1

        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }
}
