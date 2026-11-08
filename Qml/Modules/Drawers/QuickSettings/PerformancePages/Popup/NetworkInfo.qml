pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: root

    readonly property bool isWired: SystemUsage.statusWiredInterface === "connected" && (Networking.wifiEnabled ?? null)

    function               rowValue(rowIndex: int): string {
        switch (rowIndex) {
        case 0:
            return root.isWired ? qsTr("Connected") : qsTr("Disconnected");
        case 1:
            return (root.isWired ? SystemUsage.wiredLinkSpeed : SystemUsage.wirelessLinkSpeed) + " Mbps";
        case 2:
            return root.isWired ? "0 dBm" : "-70 dBm";
        case 3:
            return SystemUsage.formatUsageMiB(SystemUsage.totalWirelessUploadUsage);
        case 4:
            return SystemUsage.formatUsageMiB(SystemUsage.totalWiredUploadUsage);
        case 5:
            return SystemUsage.formatUsageMiB(SystemUsage.totalWirelessDownloadUsage);
        default:
            return SystemUsage.formatUsageMiB(SystemUsage.totalWiredDownloadUsage);
        }
    }

    icon: isWired ? "lan" : "network_wifi"
    text: qsTr("Network")
    content: ColumnLayout {

        StyledText {
            color: Colours.m3Colors.m3Green
            font.pixelSize: Appearance.fonts.size.large
            text: root.isWired ? qsTr("Ethernet") : qsTr("Wi-Fi")
        }

        Repeater {
            model: [qsTr("Status"), qsTr("Link speed"), qsTr("Signal strength"), qsTr("Total wireless upload"), qsTr("Total wired upload"), qsTr("Total wireless download"), qsTr("Total wired download")]
            delegate: RowLayout {
                id: networkRow

                required property int    index
                required property string modelData

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: networkRow.modelData + ": "
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: root.rowValue(networkRow.index)
                }
            }
        }
    }
}
