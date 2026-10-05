pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
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

    ClippingWrapperRectangle {
        anchors.fill: parent
        bottomLeftRadius: Appearance.rounding.large * 1.23
        bottomRightRadius: bottomLeftRadius
        color: "transparent"

        Sun {
        }
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

    component Sun: Shape {
        id: sunShape

        property color hillColor: Colours.m3Colors.m3Primary
        property color sunColor: Colours.m3Colors.m3Yellow
        property real sunSize: 20

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Hill
        ShapePath {
            fillColor: sunShape.hillColor
            startX: 0
            startY: sunShape.height
            strokeColor: "transparent"

            PathLine {
                x: geometry.hillStartX
                y: geometry.hillStartY
            }
            PathCubic {
                control1X: geometry.hillControlPoint1X
                control1Y: geometry.hillControlPoint1Y
                control2X: geometry.hillControlPoint2X
                control2Y: geometry.hillControlPoint2Y
                x: geometry.hillEndX
                y: geometry.hillEndY
            }
            PathLine {
                x: sunShape.width
                y: sunShape.height
            }
            PathLine {
                x: 0
                y: sunShape.height
            }
        }

        // Sun
        ShapePath {
            fillColor: sunShape.sunColor
            strokeColor: sunShape.sunColor
            strokeWidth: 2

            PathAngleArc {
                centerX: geometry.sunX
                centerY: geometry.sunY
                radiusX: sunShape.sunSize / 2
                radiusY: sunShape.sunSize / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
        QtObject {
            id: geometry

            readonly property real heightPx: sunShape.parent.height
            property real hillBaseY: heightPx - hillHeight
            property real hillControlPoint1X: widthPx * 0.3
            property real hillControlPoint1Y: hillBaseY - hillHeight * 0.1
            property real hillControlPoint2X: widthPx * 0.7
            property real hillControlPoint2Y: hillBaseY - hillHeight * 0.1
            property real hillEndX: widthPx
            property real hillEndY: hillBaseY + hillHeight * 0.3
            property real hillHeight: heightPx * 0.6
            property real hillStartX: 0
            property real hillStartY: hillBaseY + hillHeight * 0.3
            property real oneMinusProgress: 1 - progress
            property real progress: canvas.sunriseProgress
            property real sunX: Math.pow(oneMinusProgress, 3) * hillStartX + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1X + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2X + Math.pow(progress, 3) * hillEndX
            property real sunY: Math.pow(oneMinusProgress, 3) * hillStartY + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1Y + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2Y + Math.pow(progress, 3) * hillEndY

            // foking binding loop
            readonly property real widthPx: sunShape.parent.width
        }
    }
}
