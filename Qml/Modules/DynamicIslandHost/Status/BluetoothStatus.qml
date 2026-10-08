pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

import qs.Services

Scope {
    id: root

    readonly property var connectedDevices: root.devices.filter(device => device.connected)
    readonly property var devices: Bluetooth.devices.values // qmllint disable
    readonly property var pairedDevices: root.devices.filter(device => device.paired)
    readonly property var pairingDevices: root.devices.filter(device => device.pairing)

    property bool         sampled: false
    property var          snapshot: ({})

    function              announce(before, after) {
        if (after.pairing && !before.pairing)
            StatusNotifications.notify("bluetooth_searching", qsTr("Pairing with %1").arg(after.name), "", "primary");
        else if (after.paired && !before.paired)
            StatusNotifications.notify("bluetooth", qsTr("%1 paired").arg(after.name), "", "success");
        else if (after.connected && !before.connected)
            StatusNotifications.notify("bluetooth_connected", qsTr("Bluetooth connected"), after.name, "success");
        else if (!after.connected && before.connected)
            StatusNotifications.notify("bluetooth_disabled", qsTr("Bluetooth disconnected"), after.name, "error");
    }
    function              buildSnapshot() {
        const map = {};
        for (const device of root.devices) {
            map[device.address] = {
                connected: device.connected,
                name: device.name || device.deviceName || device.address,
                paired: device.paired,
                pairing: device.pairing
            };
        }
        return map;
    }
    function              sample() {
        root.snapshot = root.buildSnapshot();
        root.sampled  = true;
    }
    function              sync() {
        if (!root.sampled) {
            // A host with no adapter enumerates an empty model forever, so the
            // grace timer below is what guarantees the snapshot gets taken.
            if (root.devices.length > 0)
                root.sample();
            return;
        }

        const next     = root.buildSnapshot();
        const previous = root.snapshot;
        root.snapshot  = next;

        for (const address of Object.keys(next)) {
            const before = previous[address];
            if (before === undefined) {
                if (next[address].connected)
                    StatusNotifications.notify("bluetooth_connected", qsTr("Bluetooth connected"), next[address].name, "success");
                continue;
            }
            root.announce(before, next[address]);
        }
        // A device dropped out of the model entirely while connected.
        for (const address of Object.keys(previous)) {
            if (next[address] !== undefined || !previous[address].connected)
                continue;
            StatusNotifications.notify("bluetooth_disabled", qsTr("Bluetooth disconnected"), previous[address].name, "error");
        }
    }

    Component.onCompleted: graceTimer.start()

    Timer {
        id: graceTimer

        interval: 1500
        repeat: false
        onTriggered: root.sync()
    }

    Connections {
        function onConnectedDevicesChanged() {
            root.sync();
        }
        function onPairedDevicesChanged() {
            root.sync();
        }
        function onPairingDevicesChanged() {
            root.sync();
        }

        target: root
    }
}
