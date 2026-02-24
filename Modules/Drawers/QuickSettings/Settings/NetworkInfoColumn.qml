pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

RowLayout {
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Appearance.spacing.normal

    EthernetCard {}
    WiFiCard {}

    component EthernetCard: StyledRect {
        id: ethernetCard

        Layout.fillWidth: true
        implicitHeight: 70
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        readonly property bool isConnected: SystemUsage.statusWiredInterface === "connected"

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.fillHeight: true
                color: ethernetCard.isConnected ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    type: Icon.Material
                    anchors.centerIn: parent
                    icon: "settings_ethernet"
                    color: ethernetCard.isConnected ? Colours.m3Colors.m3OnPrimary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge * 0.8
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Ethernet")
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.Medium
                        color: Colours.m3Colors.m3OnSurface
                    }

                    StyledText {
                        text: `(${SystemUsage.statusVPNInterface})`
                        visible: SystemUsage.statusVPNInterface !== ""
                        font.pixelSize: Appearance.fonts.size.small
                        color: Colours.m3Colors.m3OnSurface
                    }
                }

                StyledText {
                    text: SystemUsage.statusWiredInterface === "connected" ? qsTr("Connected") : qsTr("Not Connected")
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }
        }
    }

    component WiFiCard: StyledRect {
        id: wifiCard

        Layout.fillWidth: true
        implicitHeight: 70
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        MArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: content && content.wifi.isVisible ? Qt.ArrowCursor : Qt.PointingHandCursor
            enabled: content && !content.wifi.isVisible
            onClicked: {
                if (content)
                    content.wifi.isVisible = !content.wifi.isVisible;
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                color: Networking.wifiEnabled && Wifi.activeWifiNetwork.connected ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    type: Icon.Material
                    anchors.centerIn: parent
                    icon: Networking.wifiEnabled && Wifi.activeWifiNetwork.connected ? Wifi.getWiFiIcon(Wifi.activeWifiNetwork.signalStrength) : "wifi_off"
                    color: Networking.wifiEnabled && Wifi.activeWifiNetwork.connected ? Colours.m3Colors.m3OnPrimary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: qsTr("Internet")
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledText {
                    text: {
                        if (Networking.wifiEnabled && Wifi.activeWifiNetwork.connected)
                            return Wifi.activeWifiNetwork.name;
                        else
                            return qsTr("WiFi Disconnected");
                    }
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Medium
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colours.m3Colors.m3OnSurface
                }
            }
        }
    }
}
