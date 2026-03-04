pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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
    readonly property string upstreamInterface: {
        const eth = SystemUsage.allEthernetDevices.find(d => d.isActive);
        return eth ? eth.name : SystemUsage.wiredInterface;
    }

    // Prefer a disconnected wifi device so we don't drop the current AP connection
    // readonly property string hotspotInterface: {
    //     const free = SystemUsage.allWifiDevices?.find(d => !d.isActive);
    //     return free?.name ?? SystemUsage.wirelessInterface ?? "";
    // }

    property string ssid: "MyHotspot"
    property string password: "password123"
    property string band: "bg" // "bg" = 2.4 GHz, "a" = 5 GHz
    property string hotspotInterface: "wlp3s0"
    property int channel: 6
    property int status: Hotspot.Status.Inactive
    property string errorMessage: ""

    Component.onCompleted: _queryStatus.running = true

    function start() {
        if (root.status === Hotspot.Status.Active || root.status === Hotspot.Status.Starting)
            return;
        if (!root.hotspotInterface) {
            _setError("No wireless interface available");
            return;
        }
        root.status = Hotspot.Status.Starting;
        root.errorMessage = "";
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
        }
    }

    Process {
        id: _stopHotspot

        command: ["bash", "-c", "nmcli con down Hotspot; nmcli con delete Hotspot"]
        onExited: code => {
            if (code !== 0)
                console.warn("[Hotspot] Stop exited with code", code, stderr);
            root.status = Hotspot.Status.Inactive;
            console.info("[Hotspot] Hotspot stopped");
        }
    }

    Process {
        id: _queryStatus

        command: ["nmcli", "-t", "-f", "NAME,STATE", "con", "show", "--active"]
        onExited: () => {
            if (stdout.split("\n").some(line => line.startsWith("Hotspot:")))
                root.status = Hotspot.Status.Active;
        }
    }
}
