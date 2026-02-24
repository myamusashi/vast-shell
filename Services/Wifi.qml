pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property list<WifiDevice> devices: Networking.devices.values
    readonly property list<Network> networks: Networking.devices.values[0].networks.values
    readonly property WifiDevice activeWifiDevice: devices[0] ?? null
    readonly property WifiNetwork activeWifiNetwork: networks[0] ?? null

    function getWiFiIcon(strength) {
        if (strength >= 0.8)
            return "network_wifi";
        if (strength >= 0.5)
            return "network_wifi_3_bar";
        if (strength >= 0.3)
            return "network_wifi_2_bar";
        if (strength >= 0.15)
            return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }
}
