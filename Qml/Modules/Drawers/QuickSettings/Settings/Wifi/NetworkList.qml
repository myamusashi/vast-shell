pragma ComponentBehavior: Bound

import QtQuick
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
    implicitHeight: contentHeight
    interactive: false
    model: Networking.devices
    spacing: Appearance.spacing.small
    clip: true

    delegate: ColumnLayout {
        id: deviceDelegate

        required property WifiDevice modelData

        width: root.width

        Connections {
            target: GlobalStates

            function onIsWifiScannerOpenChanged() {
                deviceDelegate.modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
            }
        }

        Component.onCompleted: {
            modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
        }

        Repeater {
            model: ScriptModel {
                values: {
                    if (deviceDelegate.modelData.type !== DeviceType.Wifi) // qmllint disable
                        return [];
                    return WifiUtils.sorted([...deviceDelegate.modelData.networks.values]);
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
