pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

import qs.Services

Singleton {
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter // qmllint disable
    readonly property bool adapterAvailable: adapter !== null
    readonly property bool adapterBlocked: adapter ? adapter.state === BluetoothAdapterState.Blocked : false // qmllint disable
    readonly property bool adapterEnabled: adapter ? adapter.enabled : false
    readonly property var availableDevices: BluetoothDeviceIndex.availableDevices(Bluetooth.devices.values, adapter) // qmllint disable

    readonly property var blockedDevices: BluetoothDeviceIndex.blockedDevices(Bluetooth.devices.values, adapter) // qmllint disable

    readonly property string cardIconName: BluetoothDeviceFormatter.cardIconName(hasAdapter, isPowered, hasConnected, adapter ? adapter.discovering : false)
    readonly property string cardSubtitle: BluetoothDeviceFormatter.cardSubtitle(hasAdapter, isPowered, hasConnected, connectedCount, adapter ? adapter.discovering : false)
    readonly property int connectedCount: BluetoothDeviceIndex.connectedCount(Bluetooth.devices.values, adapter) // qmllint disable
    readonly property bool discoverable: adapter ? adapter.discoverable : false
    readonly property bool hasAdapter: adapterAvailable
    readonly property bool hasBlocked: BluetoothDeviceIndex.hasWhere(Bluetooth.devices.values, adapter, "blocked") // qmllint disable

    readonly property bool hasConnected: connectedCount > 0
    readonly property bool hasPaired: BluetoothDeviceIndex.hasWhere(Bluetooth.devices.values, adapter, "paired") // qmllint disable

    readonly property string headerSubtitle: BluetoothDeviceFormatter.headerSubtitle(adapterAvailable, adapterBlocked, adapter ? adapter.state : -1, adapterEnabled, isDiscovering) // qmllint disable

    readonly property bool isDiscovering: adapter ? adapter.discovering : false
    readonly property bool isPowered: adapterEnabled
    readonly property bool pairable: adapter ? adapter.pairable : false
    readonly property var pairedDevices: BluetoothDeviceIndex.pairedDevices(Bluetooth.devices.values, adapter) // qmllint disable

    function addressLine(device): string {
        return BluetoothDeviceFormatter.addressLine(device);
    }
    function displayName(device): string {
        return BluetoothDeviceFormatter.displayName(device);
    }
    function setDiscoverable(checked: bool): void {
        if (adapter)
            adapter.discoverable = checked;
    }
    function setDiscovering(checked: bool): void {
        if (adapter)
            adapter.discovering = checked;
    }
    function setEnabled(checked: bool): void {
        if (adapter)
            adapter.enabled = checked;
    }
    function setPairable(checked: bool): void {
        if (adapter)
            adapter.pairable = checked;
    }
    function stateString(device): string {
        return BluetoothDeviceFormatter.stateString(device);
    }
}
