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

    property real moonriseProgress: CelestialProgress.progressBetween(Weather.moonRise, Weather.moonSet)

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square
    implicitHeight: 150
    implicitWidth: 150

    ClippingWrapperRectangle {
        anchors.fill: parent
        bottomLeftRadius: Appearance.rounding.large * 1.23
        bottomRightRadius: bottomLeftRadius
        color: "transparent"

        MoonArcShape {}
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
            icon: "bedtime"
            type: Icon.Material
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            text: qsTr("Moon")
        }
    }

    WrapperItem {
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
                        Layout.alignment: Qt.AlignVCenter
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
                            text: FormatTimeUtils.convertTo12Hour(Weather.moonRise)
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: childrenRect.height
                        implicitWidth: childrenRect.width

                        Icon {
                            id: moonsetIcon

                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            icon: "vertical_align_bottom"
                            type: Icon.Material
                        }

                        StyledText {
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.small
                            text: FormatTimeUtils.convertTo12Hour(Weather.moonSet)

                            anchors {
                                left: moonsetIcon.right
                                leftMargin: 4
                                verticalCenter: moonsetIcon.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    component MoonArcShape: ShaderEffect {
        id: moonShape

        property color    bodyColor: moonColor
        property real     bodySize: moonSize
        property color    hillColor: Colours.m3Colors.m3Primary
        property color    moonColor: Colours.m3Colors.m3OnSurface
        property real     moonSize: 20
        property real     progress: canvas.moonriseProgress
        property vector2d resolution: Qt.vector2d(width, height)

        anchors.fill: parent
        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/celestialArc.frag.qsb"
    }
}
