import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import qs.Services

StyledRect {
    id: root

    property alias trackColor: background.color
    property alias indicatorColor: indicatorPath.fillColor
    property alias cornerRadius: background.radius

    property bool condition: false
    property real waveAmplitude: 0
    property real waveFrequency: 8
    property real waveAnimationPhase: 0

    Layout.fillWidth: true
    height: 4
    visible: condition
    color: "transparent"

    StyledRect {
        id: background
        anchors.fill: parent
        color: Colours.m3Colors.m3SurfaceContainerHighest
        radius: 2
    }

    Shape {
        id: indicatorShape

        anchors.fill: parent

        property real barPosition: 0
        property real barWidth: parent.width * 0.35

        preferredRendererType: Shape.CurveRenderer

        function clampedRect() {
            var startX = Math.max(0, barPosition);
            var endX = Math.min(width, barPosition + barWidth);
            return {
                startX: startX,
                drawWidth: endX - startX
            };
        }

        function wavePath() {
            var r = clampedRect();
            if (r.drawWidth <= 0 || barPosition > width || (barPosition + barWidth) < 0)
                return "M 0 0";

            var steps = Math.max(Math.floor(r.drawWidth / 2), 20);
            var d = "";

            // Forward pass — bottom edge of the wave band
            for (var i = 0; i <= steps; i++) {
                var x = r.startX + r.drawWidth * (i / steps);
                var wo = Math.sin((x / width) * Math.PI * 2 * root.waveFrequency + root.waveAnimationPhase) * root.waveAmplitude;
                var yTop = height / 2 + wo - height / 2;
                var yBottom = height / 2 + wo + height / 2;
                d += (i === 0 ? "M " + x + " " + yTop + " L " : " L ") + x + " " + yBottom;
            }

            // Backward pass — top edge of the wave band
            for (var j = steps; j >= 0; j--) {
                var x2 = r.startX + r.drawWidth * (j / steps);
                var wo2 = Math.sin((x2 / width) * Math.PI * 2 * root.waveFrequency + root.waveAnimationPhase) * root.waveAmplitude;
                d += " L " + x2 + " " + (height / 2 + wo2 - height / 2);
            }

            return d + " Z";
        }

        function roundedRectPath() {
            var r = clampedRect();
            if (r.drawWidth <= 0 || barPosition > width || (barPosition + barWidth) < 0)
                return "M 0 0";

            var x = r.startX, w = r.drawWidth, h = height, cr = root.cornerRadius;
            return "M " + (x + cr) + " 0" + " L " + (x + w - cr) + " 0" + " A " + cr + " " + cr + " 0 0 1 " + (x + w) + " " + cr + " L " + (x + w) + " " + (h - cr) + " A " + cr + " " + cr + " 0 0 1 " + (x + w - cr) + " " + h + " L " + (x + cr) + " " + h + " A " + cr + " " + cr + " 0 0 1 " + x + " " + (h - cr) + " L " + x + " " + cr + " A " + cr + " " + cr + " 0 0 1 " + (x + cr) + " 0 Z";
        }

        ShapePath {
            id: indicatorPath
            fillColor: Colours.m3Colors.m3Primary
            strokeColor: "transparent"

            PathSvg {
                // Reactive binding — recomputes automatically whenever any
                // dependency (barPosition, barWidth, waveAnimationPhase, …) changes.
                path: root.waveAmplitude > 0 ? indicatorShape.wavePath() : indicatorShape.roundedRectPath()
            }
        }

        SequentialAnimation {
            id: loadingAnimation

            loops: Animation.Infinite
            running: root.visible

            ParallelAnimation {
                NAnim {
                    target: indicatorShape
                    property: "barWidth"
                    from: root.width * 0.0
                    to: root.width * 0.75
                }
                NAnim {
                    target: indicatorShape
                    property: "barPosition"
                    from: 0
                    to: root.width * 0.25
                }
            }
            ParallelAnimation {
                NAnim {
                    target: indicatorShape
                    property: "barWidth"
                    from: root.width * 0.75
                    to: root.width * 0.0
                }
                NAnim {
                    target: indicatorShape
                    property: "barPosition"
                    from: root.width * 0.25
                    to: root.width
                }
            }
        }
    }
}
