pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import "Markdown"

Pages {
    id: root

    property real sunriseProgress: CelestialProgress.progressBetween(Weather.sunRise, Weather.sunSet)

    content: Sun {
    }

    component Sun: Column {
        clip: true
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            topMargin: 20
        }
        Header {
            icon: "wb_sunny"
            title: qsTr("Sun")

            onClicked: root.isOpen = false
        }
        WrapperRectangle {
            color: Colours.m3Colors.m3SurfaceContainer
            implicitHeight: parent.height * 0.3
            implicitWidth: parent.width
            radius: Appearance.rounding.normal

            SunShape {
                sunSize: 40

                StyledRect {
                    anchors.bottom: parent.bottom
                    clip: true
                    color: Qt.alpha(Colours.m3Colors.m3Surface, 0.4)
                    implicitHeight: parent.height * 0.4
                    implicitWidth: parent.width
                    radius: 0

                    StyledRect {
                        anchors.top: parent.top
                        bottomLeftRadius: Appearance.rounding.normal
                        bottomRightRadius: bottomLeftRadius
                        color: Colours.m3Colors.m3OutlineVariant
                        implicitHeight: 1
                        implicitWidth: parent.width
                        radius: 0
                    }
                }
            }
        }
        Column {
            height: parent.height * 0.7
            spacing: Appearance.spacing.large * 1.5
            width: parent.width

            Row {
                height: 40
                width: parent.width

                Column {
                    spacing: 0
                    width: parent.width / 2

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.large
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Sunrise")
                        width: parent.width
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        horizontalAlignment: Text.AlignHCenter
                        text: Weather.sunRise
                        width: parent.width
                    }
                }
                Column {
                    spacing: 0
                    width: parent.width / 2

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.large
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Sunset")
                        width: parent.width
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        horizontalAlignment: Text.AlignHCenter
                        text: Weather.sunSet
                        width: parent.width
                    }
                }
            }
            WrapperRectangle {
                color: Colours.m3Colors.m3Surface
                implicitHeight: description.contentHeight + 20
                implicitWidth: parent.width
                margin: 20
                radius: Appearance.rounding.normal

                border {
                    color: Colours.m3Colors.m3Outline
                    width: 1
                }
                StyledText {
                    id: description

                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: DetailText.sun
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                }
            }
        }
    }
    component SunShape: Shape {
        id: sunShape

        property real hillBaseY: height - hillHeight
        property color hillColor: Colours.m3Colors.m3Primary
        property real hillControlPoint1X: width * 0.3
        property real hillControlPoint1Y: hillBaseY - hillHeight * 0.1
        property real hillControlPoint2X: width * 0.7
        property real hillControlPoint2Y: hillBaseY - hillHeight * 0.1
        property real hillEndX: width
        property real hillEndY: hillBaseY + hillHeight * 0.3

        // Hill geometry
        property real hillHeight: height * 0.6
        property real hillStartX: 0
        property real hillStartY: hillBaseY + hillHeight * 0.3
        property real oneMinusProgress: 1 - progress

        // Sun position — cubic bezier evaluated at progress = root.sunriseProgress
        property real progress: root.sunriseProgress
        property color sunColor: Colours.m3Colors.m3Yellow
        property real sunSize: 20
        property real sunX: Math.pow(oneMinusProgress, 3) * hillStartX + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1X + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2X + Math.pow(progress, 3) * hillEndX
        property real sunY: Math.pow(oneMinusProgress, 3) * hillStartY + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1Y + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2Y + Math.pow(progress, 3) * hillEndY

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Hill
        ShapePath {
            fillColor: sunShape.hillColor
            startX: 0
            startY: sunShape.height
            strokeColor: "transparent"

            PathLine {
                x: sunShape.hillStartX
                y: sunShape.hillStartY
            }
            PathCubic {
                control1X: sunShape.hillControlPoint1X
                control1Y: sunShape.hillControlPoint1Y
                control2X: sunShape.hillControlPoint2X
                control2Y: sunShape.hillControlPoint2Y
                x: sunShape.hillEndX
                y: sunShape.hillEndY
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
                centerX: sunShape.sunX
                centerY: sunShape.sunY
                radiusX: sunShape.sunSize / 2
                radiusY: sunShape.sunSize / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
    }
}
