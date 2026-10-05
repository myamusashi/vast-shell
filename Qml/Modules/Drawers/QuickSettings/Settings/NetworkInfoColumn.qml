pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

ColumnLayout {
    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        EthernetCard {
        }
        WiFiCard {
        }
    }
    BluetoothCard {
    }

    component BluetoothCard: StyledRect {
        id: bluetoothCardComopnent

        readonly property string cardIconName: BluetoothServices.cardIconName
        readonly property string cardSubtitle: BluetoothServices.cardSubtitle
        readonly property bool hasConnected: BluetoothServices.hasConnected
        readonly property bool isPowered: BluetoothServices.isPowered

        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: 70
        radius: Appearance.rounding.normal

        MArea {
            anchors.fill: parent
            cursorShape: content && content.bluetooth.isVisible ? Qt.ArrowCursor : Qt.PointingHandCursor // qmllint disable
            enabled: content && !content.bluetooth.isVisible // qmllint disable
            hoverEnabled: true

            onClicked: {
                if (content) // qmllint disable
                    content.bluetooth.isVisible = !content.bluetooth.isVisible; // qmllint disable
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                color: bluetoothCardComopnent.hasConnected ? Colours.m3Colors.m3Primary : bluetoothCardComopnent.isPowered ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    anchors.centerIn: parent
                    color: bluetoothCardComopnent.hasConnected ? Colours.m3Colors.m3OnPrimary : bluetoothCardComopnent.isPowered ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    icon: bluetoothCardComopnent.cardIconName
                    type: Icon.Material
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                    text: qsTr("Bluetooth")
                }
                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Medium
                    text: bluetoothCardComopnent.cardSubtitle
                    width: parent.width
                }
            }
        }
    }
    component EthernetCard: StyledRect {
        id: ethernetCard

        readonly property bool isConnected: (wiredDevice?.state ?? ConnectionState.Disconnected) === ConnectionState.Connected
        readonly property WiredDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null

        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: 70
        radius: Appearance.rounding.normal

        MArea {
            anchors.fill: parent
            cursorShape: content && content.ethernet.isVisible ? Qt.ArrowCursor : Qt.PointingHandCursor // qmllint disable
            enabled: content && !content.ethernet.isVisible // qmllint disable
            hoverEnabled: true

            onClicked: {
                if (content) // qmllint disable
                    content.ethernet.isVisible = !content.ethernet.isVisible; // qmllint disable
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 50
                color: ethernetCard.isConnected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    anchors.centerIn: parent
                    color: ethernetCard.isConnected ? Colours.m3Colors.m3OnPrimary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge * 0.8
                    icon: "settings_ethernet"
                    type: Icon.Material
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.Medium
                        text: qsTr("Ethernet")
                    }
                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.small
                        text: `(${SystemUsage.statusVPNInterface})`
                        visible: SystemUsage.statusVPNInterface !== ""
                    }
                }
                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    text: ethernetCard.isConnected ? qsTr("Connected") : qsTr("Not Connected")
                }
            }
        }
    }
    component WiFiCard: StyledRect {
        id: wifiCard

        readonly property var connectedNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null
        readonly property bool isConnected: Networking.wifiEnabled && (connectedNetwork?.connected ?? false)

        // Pure declarative bindings — no manual update functions needed
        readonly property WifiDevice wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: 70
        radius: Appearance.rounding.normal

        MArea {
            anchors.fill: parent
            cursorShape: content && content.wifi.isVisible ? Qt.ArrowCursor : Qt.PointingHandCursor // qmllint disable
            enabled: content && !content.wifi.isVisible // qmllint disable
            hoverEnabled: true

            onClicked: {
                if (content) // qmllint disable
                    content.wifi.isVisible = !content.wifi.isVisible; // qmllint disable
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                color: wifiCard.isConnected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    anchors.centerIn: parent
                    color: wifiCard.isConnected ? Colours.m3Colors.m3OnPrimary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    icon: !wifiCard.isConnected ? "wifi_off" : WifiUtils.iconFor(wifiCard.connectedNetwork.signalStrength, false)
                    type: Icon.Material
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                    text: qsTr("Internet")
                }
                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Medium
                    text: wifiCard.isConnected ? wifiCard.connectedNetwork.name : qsTr("WiFi Disconnected")
                    width: parent.width
                }
            }
        }
    }
}
