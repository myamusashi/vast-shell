pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Services

Singleton {
    id: root

    enum Status {
        Inactive = 0,
        Starting = 1,
        Active = 2,
        Stopping = 3,
        ErrorStatus = 4
    }

    readonly property bool isActive: status === Hotspot.Status.Active

    // Prefer a connected ethernet device as upstream
    readonly property string upstreamInterface: SystemUsage.allEthernetDevices

    // prefer a active device as hotspot interface
    readonly property string hotspotInterface: Wifi.activeWifiDevice.name

    property string ssid: ""
    property string password: ""
    property string band: ""
    property int channel: 6
    property int status: Hotspot.Status.Inactive
    property string errorMessage: ""

    Component.onCompleted: {
        console.log(upstreamInterface);
        ToastService.show(qsTr("Upstream Interface: %1").arg(upstreamInterface), qsTr("Hotspot"), "network-wireless-hotspot-symbolic", 3000);
        _queryStatus.running = true;
    }

    function start() {
        if (root.status === Hotspot.Status.Active || root.status === Hotspot.Status.Starting)
            return;
        if (!root.hotspotInterface) {
            _setError("No wireless interface available");
            return;
        }

        // Apply defaults at start time, not at bind time
        const _ssid = root.ssid || "Quickshell";
        const _password = root.password || "password123";
        const _band = root.band || "bg";
        const _channel = root.channel || 6;

        root.status = Hotspot.Status.Starting;
        root.errorMessage = "";
        _createHotspot.command = ["bash", "-c", `nmcli con delete "Hotspot" 2>/dev/null; ` + `nmcli con add type wifi ifname ${root.hotspotInterface} ` + `con-name Hotspot autoconnect no ssid "${_ssid}" ` + `mode ap ipv4.method shared ` + `wifi-sec.key-mgmt wpa-psk ` + `wifi-sec.psk "${_password}" ` + `wifi.band ${_band} ` + `wifi.channel ${_channel}`];
        _createHotspot.running = true;
    }

    function stop() {
        if (root.status !== Hotspot.Status.Active)
            return;
        root.status = Hotspot.Status.Stopping;
        _stopHotspot.running = true;
    }

    function toggle() {
        isActive ? stop() : start();
    }

    function _setError(msg) {
        root.errorMessage = msg;
        root.status = Hotspot.Status.ErrorStatus;
        console.warn("[Hotspot] Error:", msg);
        ToastService.show(qsTr("[Hotspot] Error: %1").arg(msg), qsTr("Hotspot"), "network-wireless-hotspot-symbolic", 3000);
    }

    Process {
        id: _createHotspot

        command: ["bash", "-c", `nmcli con delete "Hotspot" 2>/dev/null; ` + `nmcli con add type wifi ifname ${root.hotspotInterface} ` + `con-name Hotspot autoconnect no ssid "${root.ssid}" ` + `mode ap ipv4.method shared ` + `wifi-sec.key-mgmt wpa-psk ` + `wifi-sec.psk "${root.password}" ` + `wifi.band ${root.band} ` + `wifi.channel ${root.channel}`]
        onExited: code => {
            if (code !== 0) {
                root._setError("Failed to create hotspot connection: " + stderr);
                return;
            }
            _startHotspot.running = true;
        }
    }

    Process {
        id: _startHotspot

        command: ["nmcli", "con", "up", "Hotspot"]
        onExited: code => {
            if (code !== 0) {
                root._setError("Failed to bring up hotspot: " + stderr);
                return;
            }
            root.status = Hotspot.Status.Active;
            console.info("[Hotspot] Active on", root.hotspotInterface, "| SSID:", root.ssid);
            ToastService.show(qsTr("[Hotspot] Active on %1 | SSID: %2").arg(root.hotspotInterface).arg(root.ssid), qsTr("Hotspot"), "network-wireless-hotspot-symbolic", 3000);
        }
    }

    Process {
        id: _stopHotspot

        command: ["bash", "-c", "nmcli con down Hotspot; nmcli con delete Hotspot"]
        onExited: code => {
            if (code !== 0) {
                console.warn("[Hotspot] Stop exited with code", code, stderr);
                ToastService.show(qsTr("[Hotspot] Stop exited with code %1: %2").arg(code).arg(stderr), qsTr("Hotspot"), "network-wireless-hotspot-symbolic", 3000);
            }
            root.status = Hotspot.Status.Inactive;
            console.info("[Hotspot] Hotspot stopped");
            ToastService.show(qsTr("Hotspot stopped"), qsTr("Hotspot"), "network-wireless-hotspot-symbolic", 3000);
        }
    }

    Process {
        id: _queryStatus

        command: ["nmcli", "-t", "-f", "NAME,STATE", "con", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim();
                if (data.split("\n").some(line => line.startsWith("Hotspot:")))
                    root.status = Hotspot.Status.Active;
            }
        }
    }
}
