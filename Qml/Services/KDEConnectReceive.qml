pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Vast.Utils as VUTILS

import qs.Services

Singleton {
    id: root

    readonly property int    dismissMs: 3000
    readonly property bool   isReceived: currentState === KDEConnectReceive.State.Received
    readonly property bool   isReceiving: currentState === KDEConnectReceive.State.Receiving
    readonly property string label: KDEConnectTransfer.label
    readonly property int    outcome: maxPercent >= 100 ? KDEConnectReceive.Outcome.Received : KDEConnectReceive.Outcome.Interrupted
    readonly property int    percent: maxPercent
    readonly property string sizeText: KDEConnectTransfer.sizeText

    property int             currentState: KDEConnectReceive.State.Idle
    property string          deviceId: ""
    property string          deviceName: ""
    property string          fileName: ""
    property Component       islandContent: null
    property int             islandRequestId: -1
    property int             maxPercent: 0 // sticky, so a dropped percentage never rewinds the island

    function                 baseName(url) {
        const raw = String(url).split("/").pop();
        try {
            return decodeURIComponent(raw);
        } catch (error) {
            return raw;
        }
    }
    function                 beginReceiving() {
        if (currentState !== KDEConnectReceive.State.Idle)
            return;
        dismissTimer.stop();
        deviceId     = "";
        deviceName   = "";
        fileName     = "";
        maxPercent   = Math.max(0, KDEConnectTransfer.percent);
        currentState = KDEConnectReceive.State.Receiving;
        root.openIsland();
    }
    function                 dismiss() {
        dismissTimer.stop();
        if (root.islandRequestId >= 0)
            DynamicIslandService.dismiss(root.islandRequestId);
        islandRequestId = -1;
        deviceId        = "";
        deviceName      = "";
        fileName        = "";
        maxPercent      = 0;
        currentState    = KDEConnectReceive.State.Idle;
    }

    enum State {
        Idle,
        Receiving,
        Received
    }
    enum Outcome {
        Received,
        Interrupted
    }
    // The window is the only end-of-transfer signal that always arrives; the
    // file name may show up before it or not at all.
    function                 finishReceiving() {
        if (currentState !== KDEConnectReceive.State.Receiving)
            return;
        currentState = KDEConnectReceive.State.Received;
        root.showResult();
        dismissTimer.restart();
    }
    function                 openIsland() {
        if (root.islandContent === null)
            return;
        // A finite result left over from an earlier transfer gives way to this one.
        if (root.islandRequestId >= 0)
            DynamicIslandService.dismiss(root.islandRequestId);
        root.islandRequestId = DynamicIslandService.show(root.islandContent, 0);
    }
    function                 recordFile(receivedDeviceId, destinationUrl) {
        deviceId     = receivedDeviceId;
        deviceName   = KDEConnect.deviceById(receivedDeviceId)?.name ?? "";
        fileName     = root.baseName(destinationUrl);
        currentState = KDEConnectReceive.State.Received;
        root.showResult();
        dismissTimer.restart();
    }
    function                 showResult() {
        if (root.islandContent === null) {
            root.islandRequestId = -1;
            return;
        }
        if (root.islandRequestId >= 0)
            DynamicIslandService.dismiss(root.islandRequestId);
        root.islandRequestId = DynamicIslandService.show(root.islandContent, root.dismissMs);
    }

    Component.onCompleted: {
        if (KDEConnectTransfer.receiving)
            root.beginReceiving();
        VUTILS.KdeConnectShare.watchDevices(KDEConnect.allDevices.map(device => device.id));
    }

    Connections {
        function onAllDevicesChanged() {
            VUTILS.KdeConnectShare.watchDevices(KDEConnect.allDevices.map(device => device.id));
        }

        target: KDEConnect
    }

    Connections {
        function onFileReceived(deviceId, destinationUrl) {
            root.recordFile(deviceId, destinationUrl);
        }

        target: VUTILS.KdeConnectShare
    }

    Connections {
        function onPercentChanged() {
            if (root.isReceiving)
                root.maxPercent = Math.max(root.maxPercent, KDEConnectTransfer.percent);
        }
        function onReceivingChanged() {
            if (KDEConnectTransfer.receiving)
                root.beginReceiving();
            else
                root.finishReceiving();
        }

        target: KDEConnectTransfer
    }

    Timer {
        id: dismissTimer

        interval: root.dismissMs
        repeat: false
        onTriggered: root.dismiss()
    }
}
