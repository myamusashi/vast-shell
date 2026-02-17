pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property bool charging: UPower.displayDevice.state == UPowerDeviceState.Charging
    property int foundBattery: 0
    property var batteries: []
    property real totalDesignCapacity: 0
    property real totalCurrentCapacity: 0
    property real overallBatteryHealth: 0

    function formatCapacity(microWh) {
        return (microWh / 1000000).toFixed(2) + " Wh";
    }

    Process {
        command: ["sh", "-c", "ls -d /sys/class/power_supply/BAT* | wc -l"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.foundBattery = parseInt(text.trim());
            }
        }
    }

    Process {
        id: batteryHealthProc

        command: ["sh", "-c", "for bat in /sys/class/power_supply/BAT*; do echo $(basename $bat); cat $bat/energy_full_design; cat $bat/energy_full; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                const batteryArray = [];
                let totalDesign = 0;
                let totalCurrent = 0;

                for (var i = 0; i < lines.length; i += 3) {
                    if (i + 2 < lines.length) {
                        const name = lines[i];
                        const designCapacity = parseInt(lines[i + 1]);
                        const currentCapacity = parseInt(lines[i + 2]);
                        const health = ((currentCapacity / designCapacity) * 100).toFixed(2);

                        batteryArray.push({
                            name: name,
                            designCapacity: designCapacity,
                            currentCapacity: currentCapacity,
                            health: parseFloat(health)
                        });

                        totalDesign += designCapacity;
                        totalCurrent += currentCapacity;
                    }
                }

                root.batteries = batteryArray;
                root.totalDesignCapacity = totalDesign;
                root.totalCurrentCapacity = totalCurrent;
                root.overallBatteryHealth = ((totalCurrent / totalDesign) * 100).toFixed(2);
            }
        }
    }
}
