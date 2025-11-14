import QtQuick
import Quickshell.Services.UPower

import qs.Data
import qs.Components

Item {
    id: root

    readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real batPercentage: UPower.displayDevice.percentage
    readonly property real batFill: (batteryBody.width - 4) * (batPercentage / 100.0)
    readonly property real chargeFill: (batteryBody.width - 4) * (chargeFillIndex / 100.0)
    property int chargeFillIndex: 0
    property int widthBattery: 26
    property int heightBattery: 12

    width: widthBattery + 4
    height: heightBattery

    StyledRect {
        id: batteryBody

        width: root.widthBattery
        height: root.heightBattery
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        border {
            width: 2
            color: root.batPercentage <= 0.2 && !root.batCharging ? "#FF3B30" : Themes.withAlpha(Themes.colors.outline, 0.5)
        }
        color: "transparent"
        radius: 6

        StyledRect {
            id: batteryFill

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.batCharging ? root.chargeFill : (parent.width - 4) * root.batPercentage
            color: {
                if (root.batCharging)
                    return Themes.colors.green;
                if (root.batPercentage <= 0.2)
                    return Themes.colors.red;
                if (root.batPercentage <= 0.5)
                    return Themes.colors.yellow;
                return Themes.colors.on_surface;
            }
            radius: parent.radius

            Behavior on width {
                NumbAnim {
                    duration: root.batCharging ? 600 : 300
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.batPercentage * 100)
            font.pixelSize: root.batCharging ? 6 : batteryBody.height * 0.65
            font.weight: Font.Bold
            color: root.batPercentage <= 0.5 ? Themes.colors.on_background : Themes.colors.surface
        }
    }

    StyledRect {
        id: batteryTip

        width: 2
        height: 5
        anchors.left: batteryBody.right
        anchors.leftMargin: 0.5
        anchors.verticalCenter: parent.verticalCenter
        color: root.batPercentage <= 0.2 && !root.batCharging ? Themes.colors.error : Themes.withAlpha(Themes.colors.outline, 0.5)
        topRightRadius: 1
        bottomRightRadius: 1
    }

    Timer {
        interval: 600
        repeat: true
        running: root.batCharging
        triggeredOnStart: true
        onTriggered: {
            root.chargeFillIndex = (root.chargeFillIndex % 10) + 1;
        }
    }
}
