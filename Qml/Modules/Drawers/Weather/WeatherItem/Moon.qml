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

    property real moonriseProgress: CelestialProgress.progressBetween(Weather.moonRise, Weather.moonSet)

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square

    ClippingWrapperRectangle {
        anchors.fill: parent
        bottomLeftRadius: Appearance.rounding.large * 1.23
        bottomRightRadius: bottomLeftRadius
        color: "transparent"

        Moon {
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

    component Moon: Shape {
        id: moonShape

        property color hillColor: Colours.m3Colors.m3Primary
        property color moonColor: Colours.m3Colors.m3OnSurfaceVariant
        property real moonSize: 20

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Hill
        ShapePath {
            fillColor: moonShape.hillColor
            startX: 0
            startY: moonGeo.heightPx
            strokeColor: "transparent"

            PathLine {
                x: moonGeo.hillStartX
                y: moonGeo.hillStartY
            }
            PathCubic {
                control1X: moonGeo.hillControlPoint1X
                control1Y: moonGeo.hillControlPoint1Y
                control2X: moonGeo.hillControlPoint2X
                control2Y: moonGeo.hillControlPoint2Y
                x: moonGeo.hillEndX
                y: moonGeo.hillEndY
            }
            PathLine {
                x: moonGeo.widthPx
                y: moonGeo.heightPx
            }
            PathLine {
                x: 0
                y: moonGeo.heightPx
            }
        }

        // Moon
        ShapePath {
            fillColor: moonShape.moonColor
            strokeColor: moonShape.moonColor
            strokeWidth: 2

            PathAngleArc {
                centerX: moonGeo.moonX
                centerY: moonGeo.moonY
                radiusX: moonShape.moonSize / 2
                radiusY: moonShape.moonSize / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
        QtObject {
            id: moonGeo

            readonly property real heightPx: moonShape.parent.height
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
            property real moonX: Math.pow(oneMinusProgress, 3) * hillStartX + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1X + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2X + Math.pow(progress, 3) * hillEndX
            property real moonY: Math.pow(oneMinusProgress, 3) * hillStartY + 3 * Math.pow(oneMinusProgress, 2) * progress * hillControlPoint1Y + 3 * oneMinusProgress * Math.pow(progress, 2) * hillControlPoint2Y + Math.pow(progress, 3) * hillEndY
            property real oneMinusProgress: 1 - progress
            property real progress: canvas.moonriseProgress
            readonly property real widthPx: moonShape.parent.width
        }
    }
}
