import QtQuick
import Quickshell.Services.UPower

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    property alias widthBattery: batteryBody.implicitWidth
    property alias heightBattery: batteryBody.implicitHeight

    readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real batPercentage: UPower.displayDevice.percentage
    readonly property real batFill: batteryBody.width * batPercentage

    implicitWidth: widthBattery
    implicitHeight: heightBattery

    Rectangle {
        id: batteryBody

        implicitWidth: 26
        implicitHeight: 12
        clip: true
        color: "transparent"
        radius: Appearance.rounding.small * 0.5

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }

        border {
            width: 2
            color: root.batPercentage <= 0.2 && !root.batCharging ? Colours.m3Colors.m3Error : Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
        }

        Rectangle {
            id: batteryFill

            anchors {
                left: parent.left
                leftMargin: 2
                top: parent.top
                topMargin: 2
                bottom: parent.bottom
                bottomMargin: 2
            }
            width: Math.max(0, (batteryBody.width - 4) * root.batPercentage)
            radius: Appearance.rounding.small * 0.5
            color: {
                if (root.batCharging)
                    return Colours.m3Colors.m3Green;
                if (root.batPercentage <= 0.2)
                    return Colours.m3Colors.m3Red;
                if (root.batPercentage <= 0.5)
                    return Colours.m3Colors.m3Yellow;
                return Colours.m3Colors.m3OnSurface;
            }
        }

        Rectangle {
            id: chargeShimmer

            visible: root.batCharging
            anchors {
                left: parent.left
                leftMargin: 2
                top: parent.top
                topMargin: 2
                bottom: parent.bottom
                bottomMargin: 2
            }
            width: Math.max(0, (batteryBody.width - 4) * root.batPercentage)
            color: "white"
            radius: Appearance.rounding.small * 0.5

            SequentialAnimation on opacity {
                running: root.batCharging
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: 0.35
                    duration: 700
                }
                NumberAnimation {
                    from: 0.35
                    to: 0
                    duration: 700
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.batPercentage * 100)
            z: 1
            font {
                pixelSize: batteryBody.height * 0.65
                weight: Font.Bold
            }
            color: root.batPercentage <= 0.5 ? Colours.m3Colors.m3OnBackground : Colours.m3Colors.m3Surface
        }
    }

    StyledRect {
        id: batteryTip

        anchors {
            left: batteryBody.right
            leftMargin: 0.5
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: 2
        implicitHeight: 5
        color: root.batPercentage <= 0.2 && !root.batCharging ? Colours.m3Colors.m3Error : Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
        topRightRadius: 1
        bottomRightRadius: 1
    }
}
