pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MaterialShape {
    id: canvas

    property real maxPressure: 2000
    property real minPressure: 0
    property real pressure: Weather.pressure

    animationDuration: 0
    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Circle

    Pressure {
        ColumnLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 30
            }
            RowLayout {
                Icon {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    font.weight: Font.DemiBold
                    icon: "vertical_align_center"
                    type: Icon.Material
                }
                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.weight: Font.DemiBold
                    text: qsTr("Pressure")
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.weight: Font.Bold
                text: Weather.pressure
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                text: "hPa"
            }
        }
    }

    component Pressure: Shape {
        id: gaugeShape

        property real normalizedValue: (canvas.pressure - canvas.minPressure) / (canvas.maxPressure - canvas.minPressure)
        property real radius: Math.min(width, height) / 2 - 10

        anchors.fill: parent
        anchors.margins: 3
        preferredRendererType: Shape.CurveRenderer

        // Background track
        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeColor: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.2)
            strokeWidth: 9

            PathAngleArc {
                centerX: gaugeShape.width / 2
                centerY: gaugeShape.height / 2
                radiusX: gaugeShape.radius
                radiusY: gaugeShape.radius
                startAngle: 135
                sweepAngle: 270
            }
        }

        // Active progress
        ShapePath {
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            strokeColor: Colours.m3Colors.m3Primary
            strokeWidth: 9

            PathAngleArc {
                centerX: gaugeShape.width / 2
                centerY: gaugeShape.height / 2
                radiusX: gaugeShape.radius
                radiusY: gaugeShape.radius
                startAngle: 135
                sweepAngle: 270 * gaugeShape.normalizedValue
            }
        }
    }
}
