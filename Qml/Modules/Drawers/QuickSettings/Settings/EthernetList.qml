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

    readonly property bool        isConnected: (wiredDevice?.state ?? ConnectionState.Disconnected) === ConnectionState.Connected
    readonly property WiredDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var         wiredNetwork: wiredDevice?.network ?? null // qmllint disable

    contentMargin: Appearance.margin.normal
    enableScroll: false
    content: ColumnLayout {
        spacing: Appearance.spacing.small
        width: root.width

        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large * 1.5
            font.weight: Font.DemiBold
            text: qsTr("Ethernet")
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: root.isConnected ? Colours.m3Colors.m3Green : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.medium
            font.weight: Font.DemiBold
            text: root.wiredDevice ? ConnectionState.toString(root.wiredDevice.state) : qsTr("No wired device")
        }

        InfoRow {
            label: qsTr("Interface")
            value: root.wiredDevice?.name ?? "—"
            visible: root.wiredDevice
        }

        InfoRow {
            label: qsTr("Link speed")
            value: root.wiredDevice?.hasLink ? `${root.wiredDevice.linkSpeed} Mbps` : "—"
            visible: root.wiredDevice
        }

        InfoRow {
            label: qsTr("Hardware address")
            value: root.wiredDevice?.address ?? "—"
            visible: root.wiredDevice
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.wiredDevice

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("Autoconnect")
            }

            Item {
                Layout.fillWidth: true
            }

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: root.wiredDevice?.autoconnect ?? false
                onToggled: Qt.callLater(() => {
                    if (root.wiredDevice)
                        root.wiredDevice.autoconnect = checked;
                })
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small * 0.5
            visible: root.wiredDevice && (root.wiredDevice.hasLink || root.wiredDevice.connected)

            ExtendedFloatingButton {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3Primary
                text: qsTr("Connect")
                textColor: Colours.m3Colors.m3OnPrimary
                visible: !root.isConnected
                onClicked: root.wiredNetwork?.connect()
            }

            ExtendedFloatingButton {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3Primary
                text: qsTr("Disconnect")
                textColor: Colours.m3Colors.m3OnPrimary
                visible: root.isConnected
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
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: infoRow.label
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignRight
            text: infoRow.value
        }
    }
}
