import QtQuick
import QtQuick.Shapes

import qs.Components
import qs.Services

StyledRect {
    id: root

    property alias textSize: styledText.font.pixelSize
    property alias text: styledText.text

    required property real value

    property color circleColor: value > 80 ? Colours.m3Colors.m3Error : value > 60 ? Colours.m3Colors.m3Tertiary : Colours.m3Colors.m3Primary
    property real fixedSize: 100
    property real textPadding: 20

    implicitWidth: fixedSize
    implicitHeight: fixedSize

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
            strokeColor: root.circleColor
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
        text: ""
        font.pixelSize: 12
        font.bold: true
        color: Colours.m3Colors.m3OnSurface
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        width: parent.width - root.textPadding * 2
    }
}
