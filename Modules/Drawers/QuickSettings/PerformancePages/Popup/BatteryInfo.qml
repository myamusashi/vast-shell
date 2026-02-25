import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Configs
import qs.Services
import qs.Components

PopupWidget {
    icon: "battery_6_bar"
    text: qsTr("Battery")
    content: ColumnLayout {
        Repeater {
            model: [
                {
                    text: qsTr("Battery level"),
                    value: (UPower.displayDevice.percentage * 100).toFixed(0) + "%"
                },
                {
                    text: qsTr("Temperature"),
                    value: SystemUsage.batteryTemp + "°C"
                },
                {
                    text: qsTr("Status"),
                    value: Battery.charging ? qsTr("Charging") : qsTr("Discharging")
                },
                {
                    text: qsTr("Technology"),
                    value: SystemUsage.batteryTechnologies
                },
                {
                    text: qsTr("Overall Health"),
                    value: Battery.overallBatteryHealth + "%"
                },
                {
                    text: qsTr("Voltage"),
                    value: UPower.displayDevice.energyCapacity + " V"
                },
            ].concat(Battery.batteries.map(function (bat, index) {
                return [
                    {
                        text: qsTr("%1 - Design Capacity").arg(bat.name),
                        value: Battery.formatCapacity(bat.designCapacity)
                    },
                    {
                        text: qsTr("%1 - Current Capacity").arg(bat.name),
                        value: Battery.formatCapacity(bat.currentCapacity)
                    },
                    {
                        text: qsTr("%1 - Health").arg(bat.name),
                        value: bat.health + "%"
                    }
                ];
            }).reduce(function (acc, val) {
                return acc.concat(val);
            }, []))
            delegate: RowLayout {
                required property var modelData
                readonly property string text: modelData.text
                readonly property string value: modelData.value

                StyledText {
                    text: parent.text + ": "
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                StyledText {
                    text: parent.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
