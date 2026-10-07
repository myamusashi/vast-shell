import QtQuick
import QtQuick.Shapes
import Quickshell.Services.UPower

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property bool  batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real  batFill: batteryBody.width * batPercentage
    readonly property real  batPercentage: UPower.displayDevice.percentage
    readonly property bool  batteryLow: batPercentage <= 0.2 && !batCharging
    readonly property real  bodyRadius: Appearance.rounding.small * 0.5
    readonly property real  fillAreaHeight: batteryBody.height - fillInset * 2
    readonly property real  fillAreaWidth: batteryBody.width - fillInset * 2
    readonly property color fillColor: {
        if (batCharging)
            return Qt.alpha(Colours.m3Colors.m3Green, 0.5);
        if (batPercentage <= 0.2)
            return Qt.alpha(Colours.m3Colors.m3Red, 0.5);
        if (batPercentage <= 0.5)
            return Qt.alpha(Colours.m3Colors.m3Yellow, 0.5);
        return Colours.m3Colors.m3OnSurface;
    }
    readonly property real  fillInset: 2
    readonly property color outlineColor: batteryLow ? Qt.alpha(Colours.m3Colors.m3Error, 0.8) : Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
    readonly property real  outlineWidth: 1

    property alias          heightBattery: batteryBody.implicitHeight
    property alias          widthBattery: batteryBody.implicitWidth

    implicitHeight: heightBattery
    implicitWidth: widthBattery

    Item {
        id: batteryBody

        implicitHeight: 12
        implicitWidth: 26

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }

        Item {
            id: fillClip

            clip: true
            height: root.fillAreaHeight
            width: Math.max(0, root.fillAreaWidth * root.batPercentage)
            x: root.fillInset
            y: root.fillInset

            Shape {
                id: fillShape

                height: root.fillAreaHeight
                preferredRendererType: Shape.CurveRenderer
                width: root.fillAreaWidth

                RoundedRectanglePath {
                    cornerRadius: root.bodyRadius - root.fillInset
                    fillColor: root.fillColor
                    rectHeight: root.fillAreaHeight
                    rectWidth: root.fillAreaWidth
                    strokeColor: "transparent"
                    strokeWidth: -1
                }
            }

            Shape {
                id: chargeShimmer

                height: root.fillAreaHeight
                preferredRendererType: Shape.CurveRenderer
                visible: root.batCharging
                width: root.fillAreaWidth
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.batCharging
                    NumberAnimation {
                        duration: 700
                        from: 0
                        to: 0.35
                    }
                    NumberAnimation {
                        duration: 700
                        from: 0.35
                        to: 0
                    }
                }

                RoundedRectanglePath {
                    cornerRadius: root.bodyRadius - root.fillInset
                    fillColor: "white"
                    rectHeight: root.fillAreaHeight
                    rectWidth: root.fillAreaWidth
                    strokeColor: "transparent"
                    strokeWidth: -1
                }
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            RoundedRectanglePath {
                cornerRadius: root.bodyRadius - root.outlineWidth / 2
                fillColor: "transparent"
                rectHeight: batteryBody.height - root.outlineWidth
                rectWidth: batteryBody.width - root.outlineWidth
                rectX: root.outlineWidth / 2
                rectY: root.outlineWidth / 2
                strokeColor: root.outlineColor
                strokeWidth: root.outlineWidth
            }
        }

        StyledText {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3Surface
            text: Math.round(root.batPercentage * 100)
            z: 1

            font {
                pixelSize: batteryBody.height * 0.65
                weight: Font.Bold
            }
        }
    }

    StyledRect {
        id: batteryTip

        bottomRightRadius: 1
        color: root.batteryLow ? Colours.m3Colors.m3Error : Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
        implicitHeight: 5
        implicitWidth: 2
        topRightRadius: 1

        anchors {
            left: batteryBody.right
            leftMargin: 0.5
            verticalCenter: parent.verticalCenter
        }
    }

    component RoundedRectanglePath: ShapePath {
        id: roundedRectPath

        readonly property real clampedRadius: Math.max(0, Math.min(cornerRadius, rectWidth / 2, rectHeight / 2))

        property real          cornerRadius: 0
        property real          rectHeight: 0
        property real          rectWidth: 0
        property real          rectX: 0
        property real          rectY: 0

        startX: rectX + clampedRadius
        startY: rectY

        PathLine {
            x: roundedRectPath.rectX + roundedRectPath.rectWidth - roundedRectPath.clampedRadius
            y: roundedRectPath.rectY
        }

        PathArc {
            radiusX: roundedRectPath.clampedRadius
            radiusY: roundedRectPath.clampedRadius
            x: roundedRectPath.rectX + roundedRectPath.rectWidth
            y: roundedRectPath.rectY + roundedRectPath.clampedRadius
        }

        PathLine {
            x: roundedRectPath.rectX + roundedRectPath.rectWidth
            y: roundedRectPath.rectY + roundedRectPath.rectHeight - roundedRectPath.clampedRadius
        }

        PathArc {
            radiusX: roundedRectPath.clampedRadius
            radiusY: roundedRectPath.clampedRadius
            x: roundedRectPath.rectX + roundedRectPath.rectWidth - roundedRectPath.clampedRadius
            y: roundedRectPath.rectY + roundedRectPath.rectHeight
        }

        PathLine {
            x: roundedRectPath.rectX + roundedRectPath.clampedRadius
            y: roundedRectPath.rectY + roundedRectPath.rectHeight
        }

        PathArc {
            radiusX: roundedRectPath.clampedRadius
            radiusY: roundedRectPath.clampedRadius
            x: roundedRectPath.rectX
            y: roundedRectPath.rectY + roundedRectPath.rectHeight - roundedRectPath.clampedRadius
        }

        PathLine {
            x: roundedRectPath.rectX
            y: roundedRectPath.rectY + roundedRectPath.clampedRadius
        }

        PathArc {
            radiusX: roundedRectPath.clampedRadius
            radiusY: roundedRectPath.clampedRadius
            x: roundedRectPath.rectX + roundedRectPath.clampedRadius
            y: roundedRectPath.rectY
        }
    }
}
