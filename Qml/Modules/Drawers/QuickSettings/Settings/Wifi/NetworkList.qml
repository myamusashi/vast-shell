pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States

ListView {
    id: root

    required property var        pskDialog

    readonly property WifiDevice wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null

    function                     syncScanner(): void {
        if (wifiDevice)
            wifiDevice.scannerEnabled = GlobalStates.isWifiScannerOpen;
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, 320)
    boundsBehavior: Flickable.StopAtBounds
    cacheBuffer: 160
    clip: true
    implicitHeight: contentHeight
    interactive: contentHeight > height
    spacing: Appearance.spacing.small
    Component.onCompleted: syncScanner()
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    delegate: NetworkDelegate {
        required property var modelData

        network: modelData
        pskDialog: root.pskDialog
        width: root.width
    }
    model: ScriptModel {
        values: {
            const device = root.wifiDevice;
            if (!device || !device.networks)
                return [];
            return WifiUtils.sorted([...device.networks.values]);
        }
    }
    onWifiDeviceChanged: syncScanner()

    Connections {

        function onIsWifiScannerOpenChanged() {
            root.syncScanner();
        }

        target: GlobalStates
    }
}
