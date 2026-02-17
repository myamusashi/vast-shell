import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Configs
import qs.Services
import qs.Components

PopupWidget {
    icon: "battery_6_bar"
    text: "Battery"
    content: ColumnLayout {
        Repeater {
            model: [
                {
                    text: "Battery level",
                    value: (UPower.displayDevice.percentage * 100).toFixed(0) + "%"
                },
                {
                    text: "Temperature",
                    value: SystemUsage.batteryTemp + "°C"
                },
                {
                    text: "Status",
                    value: Battery.charging ? "Charging" : "Discharging"
                },
                {
                    text: "Technology",
                    value: SystemUsage.batteryTechnologies
                },
                {
                    text: "Overall Health",
                    value: Battery.overallBatteryHealth + "%"
                },
                {
                    text: "Voltage",
                    value: UPower.displayDevice.energyCapacity + " V"
                },
            ].concat(Battery.batteries.map(function (bat, index) {
                return [
                    {
                        text: bat.name + " - Design Capacity",
                        value: Battery.formatCapacity(bat.designCapacity)
                    },
                    {
                        text: bat.name + " - Current Capacity",
                        value: Battery.formatCapacity(bat.currentCapacity)
                    },
                    {
                        text: bat.name + " - Health",
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
