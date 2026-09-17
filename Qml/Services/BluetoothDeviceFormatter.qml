pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    function displayName(device): string {
        if (!device)
            return "";
        return device.name || device.deviceName || device.address || "";
    }

    function stateString(device): string {
        if (!device)
            return "";
        if (device.pairing)
            return qsTr("Pairing…");
        return BluetoothDeviceState.toString(device.state);
    }

    function addressLine(device): string {
        if (!device)
            return "";
        const addr = device.address || "";
        const extra = device.pairing ? " · " + qsTr("Pairing…") : "";
        return addr + extra;
    }

    function headerSubtitle(adapterAvailable, adapterBlocked, adapterState, adapterEnabled, isDiscovering): string {
        if (!adapterAvailable)
            return qsTr("No Bluetooth adapter found");
        if (adapterBlocked)
            return qsTr("Adapter blocked (rfkill)");
        if (adapterState === BluetoothAdapterState.Enabling)
            return qsTr("Enabling…");
        if (adapterState === BluetoothAdapterState.Disabling)
            return qsTr("Disabling…");
        if (!adapterEnabled)
            return qsTr("Bluetooth is off");
        return isDiscovering ? qsTr("Scanning…") : qsTr("Tap a device to connect");
    }

    function cardSubtitle(hasAdapter, isPowered, hasConnected, connectedCount, discovering): string {
        if (!hasAdapter)
            return qsTr("No adapter");
        if (!isPowered)
            return qsTr("Off");
        if (hasConnected)
            return qsTr("%1 connected").arg(connectedCount);
        if (discovering)
            return qsTr("Scanning…");
        return qsTr("On — not connected");
    }

    function cardIconName(hasAdapter, isPowered, hasConnected, discovering): string {
        if (!hasAdapter)
            return "bluetooth_disabled";
        if (!isPowered)
            return "bluetooth_disabled";
        if (hasConnected)
            return "bluetooth_connected";
        if (discovering)
            return "bluetooth_searching";
        return "bluetooth";
    }
}
