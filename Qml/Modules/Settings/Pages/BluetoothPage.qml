pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell.Bluetooth

import qs.Components.Base
import qs.Components.Button
import qs.Components.Feedback
import qs.Core.Configs
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    pageTitle: qsTr("Bluetooth")

    SettingsCard {
        title: qsTr("Adapter")

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("No Bluetooth adapter found. Ensure Bluetooth hardware is present and BlueZ is running.")
            visible: !BluetoothServices.adapterAvailable
            wrapMode: Text.WordWrap
        }
        SettingRow {
            description: qsTr("Turn the Bluetooth adapter on or off.")
            label: qsTr("Enable Bluetooth:")
            visible: BluetoothServices.adapterAvailable

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: BluetoothServices.adapterEnabled
                enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked

                onToggled: BluetoothServices.setEnabled(checked)
            }
        }
        SettingRow {
            description: qsTr("Allow nearby devices to discover this machine.")
            label: qsTr("Discoverable:")
            visible: BluetoothServices.adapterAvailable && BluetoothServices.adapterEnabled

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: BluetoothServices.discoverable

                onToggled: BluetoothServices.setDiscoverable(checked)
            }
        }
        SettingRow {
            description: qsTr("Allow nearby devices to request pairing.")
            label: qsTr("Pairable:")
            visible: BluetoothServices.adapterAvailable && BluetoothServices.adapterEnabled

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: BluetoothServices.pairable

                onToggled: BluetoothServices.setPairable(checked)
            }
        }
        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Adapter is blocked by rfkill. Unblock it with: rfkill unblock bluetooth")
            visible: BluetoothServices.adapterBlocked
            wrapMode: Text.WordWrap
        }
        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Enabling…")
            visible: BluetoothServices.adapterAvailable && BluetoothServices.adapter && BluetoothServices.adapter.state === BluetoothAdapterState.Enabling // qmllint disable
        }
        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Disabling…")
            visible: BluetoothServices.adapterAvailable && BluetoothServices.adapter && BluetoothServices.adapter.state === BluetoothAdapterState.Disabling // qmllint disable
        }
        GridLayout {
            columnSpacing: Appearance.spacing.normal
            columns: 2

            SettingRow {
                description: qsTr("Local Bluetooth adapter.")
                label: qsTr("Adapter")
                visible: BluetoothServices.adapterAvailable

                StyledText {
                    Layout.maximumWidth: 320
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.normal
                    text: {
                        if (!BluetoothServices.adapter)
                            return "—";
                        const id = BluetoothServices.adapter.adapterId || "";
                        const name = BluetoothServices.adapter.name || "";
                        if (name && id)
                            return `${name} (${id})`;
                        return name || id || "—";
                    }
                }
            }
            SettingRow {
                description: qsTr("Bluetooth device address.")
                label: qsTr("Address")
                visible: BluetoothServices.adapterAvailable

                StyledText {
                    Layout.maximumWidth: 320
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideMiddle
                    font.pixelSize: Appearance.fonts.size.small
                    text: BluetoothServices.adapter ? BluetoothServices.adapter.dbusPath : "—"
                }
            }
        }
    }
    SettingsCard {
        title: qsTr("Paired devices")
        visible: BluetoothServices.adapterEnabled

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("No paired devices")
                visible: pairedRepeater.count === 0
            }
            Repeater {
                id: pairedRepeater

                model: BluetoothServices.pairedDevices

                delegate: BluetoothDeviceDelegate {
                    required property var modelData

                    device: modelData
                    showBlockAction: true
                    showForgetAction: true

                    onBlockToggled: modelData.blocked = !modelData.blocked
                    onForgetAction: modelData.forget()
                    onPrimaryAction: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }
    SettingsCard {
        title: ""
        visible: BluetoothServices.adapterEnabled

        Progress {
            Layout.fillWidth: true
            condition: BluetoothServices.isDiscovering
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                text: qsTr("Available devices")
            }
            FloatingButton {
                backgroundRadius: Appearance.rounding.small
                color: "transparent"
                enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "bluetooth_searching"
                implicitHeight: 32
                implicitWidth: 32

                onClicked: {
                    if (BluetoothServices.isDiscovering)
                        BluetoothServices.setDiscovering(false);
                    else
                        BluetoothServices.setDiscovering(true);
                }
            }
        }
        ColumnLayout {
            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("No devices found — turn on scanning to discover nearby devices.")
                visible: availableRepeater.count === 0 && !BluetoothServices.isDiscovering
                wrapMode: Text.WordWrap
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("Searching for devices…")
                visible: availableRepeater.count === 0 && BluetoothServices.isDiscovering
            }
            Repeater {
                id: availableRepeater

                model: BluetoothServices.availableDevices

                delegate: BluetoothDeviceDelegate {
                    required property var modelData

                    device: modelData
                    showPairActions: true

                    onPrimaryAction: modelData.pair()
                    onSecondaryAction: modelData.cancelPair()
                }
            }
        }
    }
}
