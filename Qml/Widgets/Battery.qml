import QtQuick
import Quickshell.Services.UPower

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real batFill: batteryBody.width * batPercentage
    readonly property real batPercentage: UPower.displayDevice.percentage
    property alias heightBattery: batteryBody.implicitHeight
    property alias widthBattery: batteryBody.implicitWidth

    implicitHeight: heightBattery
    implicitWidth: widthBattery

    Rectangle {
        id: batteryBody

        clip: true
        color: "transparent"
        implicitHeight: 12
        implicitWidth: 26
        radius: Appearance.rounding.small * 0.5

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        border {
            color: root.batPercentage <= 0.2 && !root.batCharging ? Colours.m3Colors.m3Error : Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
            width: 2
        }
        Rectangle {
            id: batteryFill

            color: {
                if (root.batCharging)
                    return Colours.m3Colors.m3Green;
                if (root.batPercentage <= 0.2)
                    return Colours.m3Colors.m3Red;
                if (root.batPercentage <= 0.5)
                    return Colours.m3Colors.m3Yellow;
                return Colours.m3Colors.m3OnSurface;
            }
            radius: Appearance.rounding.small * 0.5
            width: Math.max(0, (batteryBody.width - 4) * root.batPercentage)

            anchors {
                bottom: parent.bottom
                bottomMargin: 2
                left: parent.left
                leftMargin: 2
                top: parent.top
                topMargin: 2
            }
        }
        Rectangle {
            id: chargeShimmer

            color: "white"
            radius: Appearance.rounding.small * 0.5
            visible: root.batCharging
            width: Math.max(0, (batteryBody.width - 4) * root.batPercentage)

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

            anchors {
                bottom: parent.bottom
                bottomMargin: 2
                left: parent.left
                leftMargin: 2
                top: parent.top
                topMargin: 2
            }
        }
        StyledText {
            anchors.centerIn: parent
            color: root.batPercentage <= 0.5 ? Colours.m3Colors.m3OnBackground : Colours.m3Colors.m3Surface
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
        color: root.batPercentage <= 0.2 && !root.batCharging ? Colours.m3Colors.m3Error : Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
        implicitHeight: 5
        implicitWidth: 2
        topRightRadius: 1

        anchors {
            left: batteryBody.right
            leftMargin: 0.5
            verticalCenter: parent.verticalCenter
        }
    }
}
