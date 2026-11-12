pragma ComponentBehavior: Bound

import QtQuick
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
    implicitHeight: 150
    implicitWidth: 150

    PressureGaugeShape {

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
                    icon: "compress"
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

    component PressureGaugeShape: ShaderEffect {
        id: gaugeShape

        property color    activeColor: Colours.m3Colors.m3Primary
        property real     maxSweepDeg: 270
        property real     normalizedValue: Math.max(0, Math.min(1, (canvas.pressure - canvas.minPressure) / (canvas.maxPressure - canvas.minPressure)))
        property real     progress: normalizedValue
        property real     radius: Math.max(0, Math.min(width, height) / 2 - 10)
        property vector2d resolution: Qt.vector2d(width, height)
        property real     startAngleDeg: 135
        property real     strokeWidth: 9
        property color    trackColor: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.2)

        anchors.fill: parent
        anchors.margins: 3
        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/arcGauge.frag.qsb"
    }
}
