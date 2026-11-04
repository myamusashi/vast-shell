pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

ColumnLayout {
    id: root

    required property bool        bluetoothOpen
    required property var         connectedWifiNetwork
    required property bool        ethernetOpen
    required property WifiDevice  wifiDevice
    required property bool        wifiOpen
    required property WiredDevice wiredDevice

    signal                        bluetoothClicked
    signal                        ethernetClicked
    signal                        wifiClicked

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        EthernetCard {}

        WiFiCard {}
    }

    BluetoothCard {}

    component BluetoothCard: StyledRect {
        id: bluetoothCardComponent

        readonly property string cardIconName: BluetoothServices.cardIconName
        readonly property string cardSubtitle: BluetoothServices.cardSubtitle
        readonly property bool   hasConnected: BluetoothServices.hasConnected
        readonly property bool   isPowered: BluetoothServices.isPowered

        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: 70
        radius: Appearance.rounding.normal

        MArea {
            anchors.fill: parent
            cursorShape: root.bluetoothOpen ? Qt.ArrowCursor : Qt.PointingHandCursor
            enabled: !root.bluetoothOpen
            hoverEnabled: true
            onClicked: root.bluetoothClicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                color: bluetoothCardComponent.hasConnected ? Colours.m3Colors.m3Primary : bluetoothCardComponent.isPowered ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    anchors.centerIn: parent
                    color: bluetoothCardComponent.hasConnected ? Colours.m3Colors.m3OnPrimary : bluetoothCardComponent.isPowered ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    icon: bluetoothCardComponent.cardIconName
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
                    text: bluetoothCardComponent.cardSubtitle
                    width: parent.width
                }
            }
        }
    }
    component EthernetCard: StyledRect {
        id: ethernetCard

        readonly property bool isConnected: (root.wiredDevice?.state ?? ConnectionState.Disconnected) === ConnectionState.Connected

        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: 70
        radius: Appearance.rounding.normal

        MArea {
            anchors.fill: parent
            cursorShape: root.ethernetOpen ? Qt.ArrowCursor : Qt.PointingHandCursor
            enabled: !root.ethernetOpen
            hoverEnabled: true
            onClicked: root.ethernetClicked()
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

        readonly property bool isConnected: Networking.wifiEnabled && (root.connectedWifiNetwork?.connected ?? false)

        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: 70
        radius: Appearance.rounding.normal

        MArea {
            anchors.fill: parent
            cursorShape: root.wifiOpen ? Qt.ArrowCursor : Qt.PointingHandCursor
            enabled: !root.wifiOpen
            hoverEnabled: true
            onClicked: root.wifiClicked()
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
                    icon: !wifiCard.isConnected ? "wifi_off" : WifiUtils.iconFor(root.connectedWifiNetwork.signalStrength, false)
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
                    text: wifiCard.isConnected ? root.connectedWifiNetwork.name : qsTr("WiFi Disconnected")
                    width: parent.width
                }
            }
        }
    }
}
