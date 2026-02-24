pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

MaterialShape {
    id: canvas

    property real pressure: Weather.pressure
    property real minPressure: 0
    property real maxPressure: 2000

    animationDuration: 0
    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Circle

    Pressure {
        ColumnLayout {
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 30
            }

            RowLayout {
                Icon {
                    type: Icon.Material
                    icon: "vertical_align_center"
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    font.weight: Font.DemiBold
                    color: Colours.m3Colors.m3OnSurface
                }

                StyledText {
                    text: qsTr("Pressure")
                    font.weight: Font.DemiBold
                    color: Colours.m3Colors.m3OnSurface
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter

                text: Weather.pressure
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.weight: Font.Bold
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter

                text: "hPa"
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
            }
        }
    }

    component Pressure: Shape {
        id: gaugeShape

        anchors.fill: parent
        anchors.margins: 3
        preferredRendererType: Shape.CurveRenderer

        property real normalizedValue: (canvas.pressure - canvas.minPressure) / (canvas.maxPressure - canvas.minPressure)
        property real radius: Math.min(width, height) / 2 - 10

        // Background track
        ShapePath {
            strokeColor: Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.2)
            strokeWidth: 9
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

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
            strokeColor: Colours.m3Colors.m3Primary
            strokeWidth: 9
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

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
