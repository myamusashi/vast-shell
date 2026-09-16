pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Components.Base
import qs.Components.Button
import qs.Components.Popup
import qs.Core.Configs
import qs.Services

ZoomPopup {
    id: root

    readonly property WiredDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool isConnected: (wiredDevice?.state ?? ConnectionState.Disconnected) === ConnectionState.Connected
    readonly property var wiredNetwork: wiredDevice?.network ?? null // qmllint disable

    contentMargin: Appearance.margin.normal
    content: ColumnLayout {
        width: root.width
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Ethernet")
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large * 1.5
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            text: root.wiredDevice ? ConnectionState.toString(root.wiredDevice.state) : qsTr("No wired device")
            color: root.isConnected ? Colours.m3Colors.m3Green : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.medium
            font.weight: Font.DemiBold
        }

        InfoRow {
            visible: root.wiredDevice
            label: qsTr("Interface")
            value: root.wiredDevice?.name ?? "—"
        }

        InfoRow {
            visible: root.wiredDevice
            label: qsTr("Link speed")
            value: root.wiredDevice?.hasLink ? `${root.wiredDevice.linkSpeed} Mbps` : "—"
        }

        InfoRow {
            visible: root.wiredDevice
            label: qsTr("Hardware address")
            value: root.wiredDevice?.address ?? "—"
        }

        RowLayout {
            visible: root.wiredDevice
            Layout.fillWidth: true

            StyledText {
                text: qsTr("Autoconnect")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
            }

            Item {
                Layout.fillWidth: true
            }

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: root.wiredDevice?.autoconnect ?? false
                onToggled: Qt.callLater(() => {
                    if (root.wiredDevice)
                        root.wiredDevice.autoconnect = checked;
                })
            }
        }

        RowLayout {
            visible: root.wiredDevice && (root.wiredDevice.hasLink || root.wiredDevice.connected)
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small * 0.5

            ExtendedFloatingButton {
                Layout.fillWidth: true
                visible: !root.isConnected
                text: qsTr("Connect")
                color: Colours.m3Colors.m3Primary
                textColor: Colours.m3Colors.m3OnPrimary
                onClicked: root.wiredNetwork?.connect()
            }

            ExtendedFloatingButton {
                Layout.fillWidth: true
                visible: root.isConnected
                text: qsTr("Disconnect")
                color: Colours.m3Colors.m3Primary
                textColor: Colours.m3Colors.m3OnPrimary
                onClicked: root.wiredNetwork?.disconnect()
            }
        }
    }

    component InfoRow: RowLayout {
        id: infoRow

        required property string label
        required property string value

        Layout.fillWidth: true

        StyledText {
            text: infoRow.label
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: infoRow.value
            elide: Text.ElideRight
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
        }
    }
}
