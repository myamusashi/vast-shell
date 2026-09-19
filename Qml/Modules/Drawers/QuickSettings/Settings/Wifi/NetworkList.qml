pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking

import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States

ListView {
    id: root

    required property var pskDialog

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, 320)
    implicitHeight: Math.min(contentHeight, 320)
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds
    model: Networking.devices
    spacing: Appearance.spacing.small
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    delegate: ColumnLayout {
        id: deviceDelegate

        required property WifiDevice modelData

        width: root.width

        Connections {
            target: GlobalStates

            function onIsWifiScannerOpenChanged() {
                if (deviceDelegate.modelData)
                    deviceDelegate.modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
            }
        }

        Component.onCompleted: {
            if (modelData)
                modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
        }

        Repeater {
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

            delegate: NetworkDelegate {
                required property var modelData

                network: modelData
                pskDialog: root.pskDialog
            }
        }
    }
}
