import QtQuick
import Quickshell.Services.UPower

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property bool  batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real  batFill: batteryBody.width * batPercentage
    readonly property real  batPercentage: chargePercent / 100
    readonly property bool  batteryLow: batPercentage <= 0.2 && !batCharging
    readonly property real  bodyRadius: Appearance.rounding.small * 0.5
    readonly property int   chargePercent: Math.round(UPower.displayDevice.percentage * 100)
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
    property int            previousChargePercent: 0
    property alias          widthBattery: batteryBody.implicitWidth

    implicitHeight: heightBattery
    implicitWidth: widthBattery
    Component.onCompleted: previousChargePercent = chargePercent
    onChargePercentChanged: {
        if (batCharging && chargePercent > previousChargePercent)
            chargePulse.restart();
        previousChargePercent = chargePercent;
    }

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
            Behavior on width {
                NAnim {}
            }

            Rectangle {
                id: fillShape

                antialiasing: true
                color: root.fillColor
                height: root.fillAreaHeight
                radius: Math.max(0, root.bodyRadius - root.fillInset)
                width: root.fillAreaWidth
            }

            Rectangle {
                id: chargeShimmer

                antialiasing: true
                color: "white"
                height: root.fillAreaHeight
                opacity: 0
                radius: Math.max(0, root.bodyRadius - root.fillInset)
                width: root.fillAreaWidth
            }
        }

        SequentialAnimation {
            id: chargePulse

            NumberAnimation {
                duration: 350
                property: "opacity"
                target: chargeShimmer
                to: 0.35
            }

            NumberAnimation {
                duration: 350
                property: "opacity"
                target: chargeShimmer
                to: 0
            }
        }

        Rectangle {
            anchors.fill: parent
            antialiasing: true
            color: "transparent"
            radius: root.bodyRadius

            border {
                color: root.outlineColor
                width: root.outlineWidth
            }
        }

        StyledText {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3Surface
            text: root.chargePercent
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
}
