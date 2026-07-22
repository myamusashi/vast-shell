import QtQuick
import QtQuick.Shapes

import qs.Core.Configs
import qs.Services
import qs.Components.Base

StyledRect {
    id: root

    property alias circleColor: shapePath.strokeColor
    property alias textSize: styledText.font.pixelSize
    property alias text: styledText.text

    required property real value

    property real textPadding: 20

    implicitWidth: 100
    implicitHeight: 100

    TextMetrics {
        id: textMetrics

        text: root.text
        font.pixelSize: root.textSize
        font.bold: true
    }

    Shape {
        id: indicatorShape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Background circle
        ShapePath {
            strokeColor: Colours.m3Colors.m3OutlineVariant
            strokeWidth: 8
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: indicatorShape.width / 2
                centerY: indicatorShape.height / 2
                radiusX: Math.min(indicatorShape.width, indicatorShape.height) / 2 - 10
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }

        // Progress arc
        ShapePath {
            id: shapePath

            strokeWidth: 8
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: indicatorShape.width / 2
                centerY: indicatorShape.height / 2
                radiusX: Math.min(indicatorShape.width, indicatorShape.height) / 2 - 10
                radiusY: radiusX
                startAngle: -90
                sweepAngle: (root.value / 100) * 360
            }
        }
    }

    StyledText {
        id: styledText

        anchors.centerIn: parent
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        color: Colours.m3Colors.m3OnSurface
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        width: parent.width - root.textPadding * 2
    }
}
