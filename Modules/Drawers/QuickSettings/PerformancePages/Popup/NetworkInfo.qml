pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Configs
import qs.Services
import qs.Components

PopupWidget {
    id: root

    readonly property bool isWired: SystemUsage.statusWiredInterface === "connected" && (Networking.wifiEnabled ?? null)

    icon: isWired ? "lan" : "network_wifi"
    text: "Network"
    content: ColumnLayout {
        StyledText {
            text: root.isWired ? "Ethernet" : "Wi-Fi"
            color: Colours.m3Colors.m3Green
            font.pixelSize: Appearance.fonts.size.large
        }

        Repeater {
            model: [
                {
                    text: "Status",
                    value: root.isWired ? "Connected" : "Disconnected"
                },
                {
                    text: "Link speed",
                    value: root.isWired ? SystemUsage.wiredLinkSpeed + " Mbps" : SystemUsage.wirelessLinkSpeed + " Mbps"
                },
                {
                    text: "Signal strength",
                    value: root.isWired ? "0 dBm" : "-70 dBm"
                },
                {
                    text: "Total wireless upload",
                    value: SystemUsage.formatUsage(SystemUsage.totalWirelessUploadUsage)
                },
                {
                    text: "Total wired upload",
                    value: SystemUsage.formatUsage(SystemUsage.totalWiredUploadUsage)
                },
                {
                    text: "Total wireless download",
                    value: SystemUsage.formatUsage(SystemUsage.totalWirelessDownloadUsage)
                },
                {
                    text: "Total wired download",
                    value: SystemUsage.formatUsage(SystemUsage.totalWiredDownloadUsage)
                }
            ]
            delegate: RowLayout {
                required property var modelData
                readonly property string text: modelData.text
                readonly property string value: modelData.value

                StyledText {
                    text: parent.text + ": "
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                StyledText {
                    text: parent.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
