pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs.Services

Scope {
    id: root

    readonly property var       device: UPower.displayDevice
    readonly property int       deviceState: root.device ? root.device.state : UPowerDeviceState.Unknown
    readonly property list<int> lowThresholds: [20, 10, 5]
    readonly property int       percentage: root.device && root.device.ready ? Math.round(root.device.percentage * 100) : 0
    readonly property bool      ready: root.device !== null && root.device.ready

    property var                firedThresholds: []
    property int                lastState: UPowerDeviceState.Unknown
    property bool               sampled: false

    function                    handlePercentage() {
        if (root.deviceState !== UPowerDeviceState.Discharging) {
            if (root.firedThresholds.length > 0)
                root.firedThresholds = [];
            return;
        }
        if (root.levelCrossed(root.percentage) < 0)
            return;

        StatusNotifications.notify("battery_alert", qsTr("Battery low"), root.percentage + "%", "error");
    }
    function                    handleState(previous, next) {
        if (next === UPowerDeviceState.Discharging && previous !== UPowerDeviceState.Discharging)
            root.firedThresholds = [];
        if (previous === next)
            return;

        if (next === UPowerDeviceState.FullyCharged) {
            StatusNotifications.notify("battery_full", qsTr("Battery full"), root.percentage + "%", "success");
            return;
        }
        if (root.isPlugged(next) && !root.isPlugged(previous)) {
            StatusNotifications.notify("bolt", qsTr("Charging started"), root.percentage + "%", "success");
        } else if (!root.isPlugged(next) && root.isPlugged(previous)) {
            StatusNotifications.notify("power", qsTr("Charging stopped"), root.percentage + "%", "primary");
        }
    }
    function                    isPlugged(value) {
        return value === UPowerDeviceState.Charging || value === UPowerDeviceState.PendingCharge || value === UPowerDeviceState.FullyCharged;
    }
    function                    levelCrossed(current) {
        const crossed = root.lowThresholds.filter(threshold => current <= threshold && !root.firedThresholds.includes(threshold));
        if (crossed.length === 0)
            return -1;

        const lowest         = crossed[crossed.length - 1];
        root.firedThresholds = root.lowThresholds.filter(threshold => threshold >= lowest);
        return lowest;
    }
    function                    sample() {
        root.lastState = root.deviceState;
        root.sampled   = true;
        root.handlePercentage();
    }
    function                    sync() {
        if (!root.sampled) {
            if (root.ready)
                root.sample();
            return;
        }
        if (!root.ready)
            return;

        root.handleState(root.lastState, root.deviceState);
        root.lastState = root.deviceState;
        root.handlePercentage();
    }

    Component.onCompleted: graceTimer.start()

    Timer {
        id: graceTimer

        interval: 1500
        repeat: false
        onTriggered: {
            if (!root.sampled && root.ready)
                root.sample();
        }
    }

    Connections {
        function onDeviceStateChanged() {
            root.sync();
        }
        function onPercentageChanged() {
            root.sync();
        }
        function onReadyChanged() {
            root.sync();
        }

        target: root
    }
}
