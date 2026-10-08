pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

import qs.Services

Scope {
    id: root

    readonly property bool   isEthernetConnected: root.wiredDevices.some(device => device.hasLink) // qmllint disable
    readonly property bool   isWifiDisabled: !Networking.wifiEnabled
    readonly property bool   ready: Networking.devices.values.length > 0
    readonly property bool   wifiConnected: !root.isWifiDisabled && root.wifiDevice !== null && root.wifiDevice.connected
    readonly property var    wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property string wifiName: root.wifiDevice ? (root.wifiDevice.networks.values.find(network => network.connected)?.name ?? "") : "" // qmllint disable
    readonly property var    wiredDevices: Networking.devices.values.filter(device => device.type === DeviceType.Wired)

    property bool            awaitingSsid: false
    property bool            ethernetWasConnected: false
    property bool            sampled: false
    property bool            wifiWasConnected: false

    // NetworkManager reports the interface up before it lists the network it
    // joined, so the connect toast waits briefly for the SSID.
    function                 announceWifi() {
        if (root.wifiName !== "") {
            root.awaitingSsid = false;
            ssidTimer.stop();
            StatusNotifications.notify("wifi", qsTr("WiFi connected"), root.wifiName, "success");
            return;
        }
        if (root.awaitingSsid)
            return;
        root.awaitingSsid = true;
        ssidTimer.start();
    }
    function                 sync() {
        if (!root.sampled) {
            if (!root.ready)
                return;
            root.ethernetWasConnected = root.isEthernetConnected;
            root.wifiWasConnected     = root.wifiConnected;
            root.sampled              = true;
            return;
        }

        if (root.wifiConnected !== root.wifiWasConnected) {
            root.wifiWasConnected = root.wifiConnected;
            if (root.wifiConnected) {
                root.announceWifi();
            } else {
                root.awaitingSsid = false;
                ssidTimer.stop();
                StatusNotifications.notify("wifi_off", qsTr("WiFi disconnected"), "", "error");
            }
        }
        if (root.isEthernetConnected !== root.ethernetWasConnected) {
            root.ethernetWasConnected = root.isEthernetConnected;
            if (root.isEthernetConnected)
                StatusNotifications.notify("lan", qsTr("Ethernet connected"), "", "success");
            else
                StatusNotifications.notify("settings_ethernet", qsTr("Ethernet disconnected"), "", "error");
        }
    }

    Component.onCompleted: graceTimer.start()

    Timer {
        id: graceTimer

        interval: 1500
        repeat: false
        onTriggered: root.sync()
    }

    Timer {
        id: ssidTimer

        interval: 800
        repeat: false
        onTriggered: {
            root.awaitingSsid = false;
            if (root.wifiConnected && root.wifiName !== "") {
                root.announceWifi();
                return;
            }
            StatusNotifications.notify("wifi", qsTr("WiFi connected"), "", "success");
        }
    }

    Connections {
        function onIsEthernetConnectedChanged() {
            root.sync();
        }
        function onWifiConnectedChanged() {
            root.sync();
        }

        target: root
    }
}
