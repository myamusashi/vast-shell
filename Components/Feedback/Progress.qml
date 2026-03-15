import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import qs.Services
import qs.Components.Base

StyledRect {
    id: root

    property alias trackColor: background.color
    property alias indicatorColor: indicatorPath.fillColor
    property alias cornerRadius: background.radius
    property alias condition: root.visible

    property real waveAmplitude: 0
    property real waveFrequency: 8
    property real waveAnimationPhase: 0

    Layout.fillWidth: true
    height: 4
    visible: false
    color: "transparent"

    Rectangle {
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
            const startX = Math.max(0, barPosition);
            const endX = Math.min(width, barPosition + barWidth);
            return {
                startX,
                drawWidth: endX - startX
            };
        }

        function wavePath(r) {
            if (r.drawWidth <= 0)
                return "M 0 0";

            const steps = Math.min(Math.max(Math.floor(r.drawWidth / 8), 12), 60);
            const halfH = height / 2;
            const phaseScale = Math.PI * 2 * root.waveFrequency / width;
            const amp = Math.min(root.waveAmplitude, halfH);  // clamp inside bounds
            const parts = [];

            // Forward pass — top edge
            for (let i = 0; i <= steps; i++) {
                const x = r.startX + r.drawWidth * (i / steps);
                const wo = Math.sin(x * phaseScale + root.waveAnimationPhase) * amp;
                parts.push(i === 0 ? `M ${x} ${halfH + wo - halfH}` : `L ${x} ${halfH + wo - halfH}`);
            }

            // Backward pass — bottom edge
            for (let j = steps; j >= 0; j--) {
                const x = r.startX + r.drawWidth * (j / steps);
                const wo = Math.sin(x * phaseScale + root.waveAnimationPhase) * amp;
                parts.push(`L ${x} ${halfH + wo + halfH}`);
            }

            parts.push("Z");
            return parts.join(" ");
        }

        function roundedRectPath() {
            var r = clampedRect();
            if (r.drawWidth <= 0)
                return "M 0 0";

            var x = r.startX, w = r.drawWidth, h = height, cr = root.cornerRadius;
            return "M " + (x + cr) + " 0" + " L " + (x + w - cr) + " 0" + " A " + cr + " " + cr + " 0 0 1 " + (x + w) + " " + cr + " L " + (x + w) + " " + (h - cr) + " A " + cr + " " + cr + " 0 0 1 " + (x + w - cr) + " " + h + " L " + (x + cr) + " " + h + " A " + cr + " " + cr + " 0 0 1 " + x + " " + (h - cr) + " L " + x + " " + cr + " A " + cr + " " + cr + " 0 0 1 " + (x + cr) + " 0 Z";
        }

        ShapePath {
            id: indicatorPath

            fillColor: Colours.m3Colors.m3Primary
            strokeColor: "transparent"

            PathSvg {
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
