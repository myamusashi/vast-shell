pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: root

    function rowLabel(rowIndex: int): string {
        switch (rowIndex) {
        case 0:
            return qsTr("Battery level");
        case 1:
            return qsTr("Temperature");
        case 2:
            return qsTr("Status");
        case 3:
            return qsTr("Technology");
        case 4:
            return qsTr("Overall Health");
        case 5:
            return qsTr("Voltage");
        default:
            const batteryIndex = Math.floor((rowIndex - 6) / 3);
            const fieldIndex = (rowIndex - 6) % 3;
            const batteryEntry = Battery.batteries[batteryIndex];
            const batteryName = batteryEntry?.name ?? "";
            if (fieldIndex === 0)
                return qsTr("%1 - Design Capacity").arg(batteryName);
            if (fieldIndex === 1)
                return qsTr("%1 - Current Capacity").arg(batteryName);
            return qsTr("%1 - Health").arg(batteryName);
        }
    }

    function rowValue(rowIndex: int): string {
        switch (rowIndex) {
        case 0:
            return (UPower.displayDevice.percentage * 100).toFixed(0) + "%";
        case 1:
            return SystemUsage.batteryTemp + "°C";
        case 2:
            return Battery.charging ? qsTr("Charging") : qsTr("Discharging");
        case 3:
            return SystemUsage.batteryTechnologies;
        case 4:
            return Battery.overallBatteryHealth + "%";
        case 5:
            return UPower.displayDevice.energyCapacity + " V";
        default:
            const batteryIndex = Math.floor((rowIndex - 6) / 3);
            const fieldIndex = (rowIndex - 6) % 3;
            const batteryEntry = Battery.batteries[batteryIndex];
            if (!batteryEntry)
                return "";
            if (fieldIndex === 0)
                return Battery.formatCapacity(batteryEntry.designCapacity);
            if (fieldIndex === 1)
                return Battery.formatCapacity(batteryEntry.currentCapacity);
            return batteryEntry.health + "%";
        }
    }

    icon: "battery_6_bar"
    text: qsTr("Battery")
    content: ColumnLayout {

        Repeater {
            model: 6 + Battery.batteries.length * 3
            delegate: RowLayout {
                id: batteryRow

                required property int index

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: root.rowLabel(batteryRow.index) + ": "
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: root.rowValue(batteryRow.index)
                }
            }
        }
    }
}
