import QtQuick
import QtQuick.Shapes

import qs.Core.Configs
import qs.Services
import qs.Components.Base

StyledRect {
    id: root

    property alias circleColor: shapePath.strokeColor
    property alias text: styledText.text
    property real textPadding: 20
    property alias textSize: styledText.font.pixelSize
    required property real value

    implicitHeight: 100
    implicitWidth: 100

    TextMetrics {
        id: textMetrics

        font.bold: true
        font.pixelSize: root.textSize
        text: root.text
    }
    Shape {
        id: indicatorShape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Background circle
        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeColor: Colours.m3Colors.m3OutlineVariant
            strokeWidth: 8

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

            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeWidth: 8

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
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        width: parent.width - root.textPadding * 2
        wrapMode: Text.WordWrap
    }
}
