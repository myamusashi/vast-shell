import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Configs
import qs.Components
import qs.Services

WrapperItem {
    anchors.fill: parent

    RowLayout {
        id: content

        Item {
            Layout.preferredWidth: parent.width * 0.5
            Layout.fillHeight: true

            ColumnLayout {
                id: settings

                anchors.fill: parent

                readonly property bool isConnected: SystemUsage.statusWiredInterface === "connected"
                property alias wifiList: wifiList

                BrightnessControls {}
                NetworkInfoColumn {}
                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 15
                    Layout.alignment: Qt.AlignLeft
                    spacing: Appearance.spacing.normal
                    StyledText {
                        font.pixelSize: Appearance.fonts.size.small
                        text: settings.isConnected ? `${SystemUsage.formatUsage(SystemUsage.totalWiredDownloadUsage)} used today (${SystemUsage.wiredInterface})` : "Not connected"
                        color: Colours.m3Colors.m3OnSurface
                    }
                    StyledText {
                        font.pixelSize: Appearance.fonts.size.small
                        text: Network.active ? `${SystemUsage.formatUsage(SystemUsage.totalWirelessDownloadUsage)} used today (${Network.active.ssid})` : "Not connected"
                        color: Colours.m3Colors.m3OnSurface
                    }
                }
                Widgets {}
                Item {
                    Layout.fillHeight: true
                }
            }

            WifiList {
                id: wifiList

                anchors.fill: parent
            }
        }

        Notifications {
            Layout.preferredWidth: parent.width * 0.5
            Layout.fillHeight: true
        }
    }
}
