pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Configs

Singleton {
    id: root

    property var allDevices: []
    property var availableDevices: []
    property string myDeviceId: ""

    readonly property bool hasAvailableDevices: availableDevices.length > 0
    readonly property bool hasDevices: allDevices.length > 0

    function refresh() {
        discoverCommand.running = true;
    }

    function shareFile(deviceId, path) {
        if (!deviceId || !path)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--share", path], "shareFile");
    }

    function shareText(deviceId, text) {
        if (!deviceId || !text)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--share-text", text], "shareText");
    }

    function sendClipboard(deviceId) {
        if (!deviceId)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--send-clipboard"], "sendClipboard");
    }

    function ping(deviceId, message) {
        if (!deviceId)
            return;
        const args = ["kdeconnect-cli", "-d", deviceId];
        if (message)
            args.push("--ping-msg", message);
        else
            args.push("--ping");
        runKdeConnect(args, "ping");
    }

    function ring(deviceId) {
        if (!deviceId)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--ring"], "ring");
    }

    function lockDevice(deviceId) {
        if (!deviceId)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--lock"], "lock");
    }

    function unlockDevice(deviceId) {
        if (!deviceId)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--unlock"], "unlock");
    }

    function pair(deviceId) {
        if (!deviceId)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--pair"], "pair");
    }

    function unpair(deviceId) {
        if (!deviceId)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--unpair"], "unpair");
    }

    function sendSms(deviceId, message, destination) {
        if (!deviceId || !message || !destination)
            return;
        runKdeConnect(["kdeconnect-cli", "-d", deviceId, "--send-sms", message, "--destination", destination], "sendSms");
    }

    function deviceById(id) {
        for (const d of root.allDevices) {
            if (d.id === id)
                return d;
        }
        return null;
    }

    function deviceByName(name) {
        for (const d of root.allDevices) {
            if (d.name === name)
                return d;
        }
        return null;
    }

    function parseDeviceList(text) {
        const lines = text.trim().split("\n").filter(l => l.trim() !== "");
        const result = [];
        for (const line of lines) {
            const match = line.match(/^(\S+)\s+(.+)$/);
            if (match)
                result.push({
                    id: match[1],
                    name: match[2].trim()
                });
        }
        return result;
    }

    function parseFullDeviceList(text) {
        const lines = text.trim().split("\n").filter(l => l.trim() !== "");
        const result = [];
        for (const line of lines) {
            const match = line.match(/^-\s+(.+?):\s+(\S+)\s+(.+)$/);
            if (match)
                result.push({
                    name: match[1],
                    id: match[2],
                    info: match[3].trim()
                });
        }
        return result;
    }

    Timer {
        id: pollTimer
        interval: Configs.kdeConnect.pollInterval
        running: Configs.kdeConnect.pollingEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: myIdProcess
        command: ["kdeconnect-cli", "--my-id"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.myDeviceId = text.trim();
            }
        }
    }

    Process {
        id: discoverCommand
        command: ["kdeconnect-cli", "--refresh"]
        onExited: { // qmllint disable
            listAvailable.running = true;
            listAll.running = true;
        }
    }

    Process {
        id: listAvailable
        command: ["kdeconnect-cli", "--list-available", "--id-name-only"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.availableDevices = root.parseDeviceList(text);
            }
        }
    }

    Process {
        id: listAll
        command: ["kdeconnect-cli", "--list-devices", "--id-name-only"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.allDevices = root.parseDeviceList(text);
            }
        }
    }

    function runKdeConnect(args, warnTag) {
        const process = kdeConnectProcess.createObject(root, {
            command: args,
            warnTag: warnTag
        });
        process.running = true;
    }

    Component {
        id: kdeConnectProcess

        Process {
            id: process

            property string warnTag: ""
            property string stderrText: ""

            stderr: StdioCollector {
                onStreamFinished: process.stderrText = text
            }

            onExited: code => { // qmllint disable
                if (code !== 0)
                    console.warn("[KDEConnect] " + process.warnTag + " failed:", process.stderrText);
                destroy();
            }
        }
    }
}
