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

    required property var pskDialog

    Layout.fillWidth: true
    Layout.preferredHeight: contentHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    implicitHeight: contentHeight
    interactive: contentHeight > height
    model: Networking.devices
    spacing: Appearance.spacing.small
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    delegate: ColumnLayout {
        id: deviceDelegate

        required property WifiDevice modelData

        width: root.width
        clip: true
        Component.onCompleted: {
            if (modelData)
                modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
        }

        Connections {
            function onIsWifiScannerOpenChanged() {
                if (deviceDelegate.modelData)
                    deviceDelegate.modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
            }

            target: GlobalStates
        }

        Repeater {
            delegate: NetworkDelegate {
                required property var modelData

                network: modelData
                pskDialog: root.pskDialog
            }
            model: ScriptModel {
                values: {
                    const device = deviceDelegate.modelData;
                    if (!device || device.type !== DeviceType.Wifi) // qmllint disable
                        return [];
                    if (!device.networks)
                        return [];
                    return WifiUtils.sorted([...device.networks.values]);
                }
            }
        }
    }
}
