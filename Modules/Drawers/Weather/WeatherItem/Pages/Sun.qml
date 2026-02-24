pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

import qs.Configs
import qs.Services
import qs.Components

import "Markdown"

Pages {
    id: root

    property real sunriseProgress: calculateSunProgress()
    content: Sun {}

    function calculateSunProgress() {
        var now = new Date();
        var currentMinutes = now.getHours() * 60 + now.getMinutes();

        var sunriseParts = Weather.sunRise.split(":");
        var sunriseMinutes = parseInt(sunriseParts[0]) * 60 + parseInt(sunriseParts[1]);

        var sunsetParts = Weather.sunSet.split(":");
        var sunsetMinutes = parseInt(sunsetParts[0]) * 60 + parseInt(sunsetParts[1]);

        if (currentMinutes < sunriseMinutes) {
            return 0;
        } else if (currentMinutes > sunsetMinutes) {
            return 1;
        } else {
            var dayLength = sunsetMinutes - sunriseMinutes;
            var elapsed = currentMinutes - sunriseMinutes;
            return elapsed / dayLength;
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.sunriseProgress = root.calculateSunProgress()
    }

    component Sun: Column {
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "wb_sunny"
            title: qsTr("Sun")
            mouseArea.onClicked: root.isOpen = false
        }

        WrapperRectangle {
            color: Colours.m3Colors.m3SurfaceContainer
            radius: Appearance.rounding.normal
            implicitWidth: parent.width
            implicitHeight: parent.height * 0.3

            SunShape {
                sunSize: 40

                StyledRect {
                    anchors.bottom: parent.bottom
                    clip: true
                    color: Colours.withAlpha(Colours.m3Colors.m3Surface, 0.4)
                    implicitWidth: parent.width
                    implicitHeight: parent.height * 0.4
                    radius: 0

                    StyledRect {
                        anchors.top: parent.top
                        radius: 0
                        bottomLeftRadius: Appearance.rounding.normal
                        bottomRightRadius: bottomLeftRadius

                        implicitWidth: parent.width
                        implicitHeight: 1
                        color: Colours.m3Colors.m3OutlineVariant
                    }
                }
            }
        }

        Column {
            width: parent.width
            height: parent.height * 0.7
            spacing: Appearance.spacing.large * 1.5
            Row {
                width: parent.width
                height: 40

                Column {
                    width: parent.width / 2
                    spacing: 0
                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Sunrise")
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.large
                    }
                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Weather.sunRise
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }
                }

                Column {
                    width: parent.width / 2
                    spacing: 0

                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("Sunset")
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.large
                    }
                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Weather.sunSet
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }
                }
            }

            WrapperRectangle {
                border {
                    width: 1
                    color: Colours.m3Colors.m3Outline
                }
                margin: 20
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3Surface
                implicitWidth: parent.width
                implicitHeight: description.contentHeight + 20

                StyledText {
                    id: description

                    text: DetailText.sun
                    color: Colours.m3Colors.m3OnSurface
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.fonts.size.normal
                }
            }
        }
    }

    component SunShape: Shape {
        id: sunShape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        property color hillColor: Colours.m3Colors.m3Primary
        property color sunColor: Colours.m3Colors.m3Yellow
        property real sunSize: 20

        // Hill geometry
        property real hillHeight: height * 0.6
        property real hillBaseY: height - hillHeight
        property real startX: 0
        property real startY: hillBaseY + hillHeight * 0.3
        property real cp1X: width * 0.3
        property real cp1Y: hillBaseY - hillHeight * 0.1
        property real cp2X: width * 0.7
        property real cp2Y: hillBaseY - hillHeight * 0.1
        property real endX: width
        property real endY: hillBaseY + hillHeight * 0.3

        // Sun position — cubic bezier evaluated at t = root.sunriseProgress
        property real t: root.sunriseProgress
        property real oneMinusT: 1 - t
        property real sunX: Math.pow(oneMinusT, 3) * startX + 3 * Math.pow(oneMinusT, 2) * t * cp1X + 3 * oneMinusT * Math.pow(t, 2) * cp2X + Math.pow(t, 3) * endX
        property real sunY: Math.pow(oneMinusT, 3) * startY + 3 * Math.pow(oneMinusT, 2) * t * cp1Y + 3 * oneMinusT * Math.pow(t, 2) * cp2Y + Math.pow(t, 3) * endY

        // Hill
        ShapePath {
            strokeColor: "transparent"
            fillColor: sunShape.hillColor

            startX: 0
            startY: sunShape.height

            PathLine {
                x: sunShape.startX
                y: sunShape.startY
            }
            PathCubic {
                control1X: sunShape.cp1X
                control1Y: sunShape.cp1Y
                control2X: sunShape.cp2X
                control2Y: sunShape.cp2Y
                x: sunShape.endX
                y: sunShape.endY
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
            strokeColor: sunShape.sunColor
            strokeWidth: 2
            fillColor: sunShape.sunColor

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
