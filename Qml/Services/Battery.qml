pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

import qs.Core.Configs

Singleton {
    id: root

    readonly property bool charging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property int  criticalLevel: Configs.generals.battery.criticalLevel
    readonly property bool discharging: UPower.displayDevice.state === UPowerDeviceState.Discharging
    readonly property int  percentage: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 100

    property var           batteries: []
    property bool          criticalNotified: false
    property int           foundBattery: 0
    property real          overallBatteryHealth: 0
    property real          totalCurrentCapacity: 0
    property real          totalDesignCapacity: 0

    function               checkCriticalLevel(): void {
        if (!UPower.displayDevice.ready || !UPower.displayDevice.isLaptopBattery)
            return;

        if (!root.discharging || root.percentage > root.criticalLevel) {
            root.criticalNotified = false;
            return;
        }

        if (root.criticalNotified)
            return;

        root.criticalNotified = true;
        CaptureNotify.sendNotification(qsTr("Critical battery level"), qsTr("Battery is at %1%. Plug in a charger immediately!").arg(root.percentage), "critical", "battery-caution", "vast-shell", []);
    }

    function               formatCapacity(microWh) {
        return (microWh / 1000000).toFixed(2) + " Wh";
    }

    Component.onCompleted: checkCriticalLevel()
    onCriticalLevelChanged: checkCriticalLevel()
    onDischargingChanged: checkCriticalLevel()
    onPercentageChanged: checkCriticalLevel()

    Connections {

        function onReadyChanged() {
            root.checkCriticalLevel();
        }

        target: UPower.displayDevice
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
                const lines        = text.trim().split('\n');
                const batteryArray = [];
                let totalDesign    = 0;
                let totalCurrent   = 0;

                for (var i = 0; i < lines.length; i += 3) {
                    if (i + 2 < lines.length) {
                        const name            = lines[i];
                        const designCapacity  = parseInt(lines[i + 1]);
                        const currentCapacity = parseInt(lines[i + 2]);
                        const health          = ((currentCapacity / designCapacity) * 100).toFixed(2);

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

                root.batteries            = batteryArray;
                root.totalDesignCapacity  = totalDesign;
                root.totalCurrentCapacity = totalCurrent;
                root.overallBatteryHealth = ((totalCurrent / totalDesign) * 100).toFixed(2);
            }
        }
    }
}
