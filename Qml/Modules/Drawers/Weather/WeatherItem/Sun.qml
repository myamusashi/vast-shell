pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MaterialShape {
    id: canvas

    property real sunriseProgress: CelestialProgress.progressBetween(Weather.sunRise, Weather.sunSet)

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square
    implicitHeight: 150
    implicitWidth: 150

    ClippingWrapperRectangle {
        anchors.fill: parent
        bottomLeftRadius: Appearance.rounding.large * 1.23
        bottomRightRadius: bottomLeftRadius
        color: "transparent"

        SunArcShape {}
    }

    RowLayout {
        implicitWidth: parent.width

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 5
        }

        Icon {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large * 1.5
            font.variableAxes: {
                "FILL": 10,
                "opsz": fontInfo.pixelSize,
                "wght": fontInfo.weight
            }
            icon: "wb_twilight"
            type: Icon.Material
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            text: qsTr("Sun")
        }
    }

    Item {
        clip: true
        implicitHeight: contentLayout.implicitHeight

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        ColumnLayout {
            id: contentLayout

            spacing: 1

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            StyledRect {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OutlineVariant
                implicitHeight: 1
            }

            StyledRect {
                Layout.fillWidth: true
                bottomLeftRadius: Appearance.rounding.full
                bottomRightRadius: bottomLeftRadius
                color: Qt.alpha(Colours.m3Colors.m3Surface, 0.5)
                implicitHeight: 60
                radius: 0

                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.margins: 0
                    spacing: 0

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.small

                        Icon {
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            icon: "vertical_align_top"
                            type: Icon.Material
                        }

                        StyledText {
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.small
                            text: FormatTimeUtils.convertTo12Hour(Weather.sunRise)
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Appearance.spacing.small

                        Icon {
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            icon: "vertical_align_bottom"
                            type: Icon.Material
                        }

                        StyledText {
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.small
                            text: FormatTimeUtils.convertTo12Hour(Weather.sunSet)
                        }
                    }
                }
            }
        }
    }

    component SunArcShape: ShaderEffect {
        id: sunShape

        property color    bodyColor: sunColor
        property real     bodySize: sunSize
        property color    hillColor: Colours.m3Colors.m3Primary
        property real     progress: canvas.sunriseProgress
        property vector2d resolution: Qt.vector2d(width, height)
        property color    sunColor: Colours.m3Colors.m3Yellow
        property real     sunSize: 20

        anchors.fill: parent
        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/celestialArc.frag.qsb"
    }
}
