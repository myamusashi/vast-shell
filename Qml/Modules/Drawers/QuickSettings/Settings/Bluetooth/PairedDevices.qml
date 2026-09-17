pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

ColumnLayout {
    spacing: Appearance.spacing.small * 0.5
    visible: BluetoothServices.adapterEnabled

    StyledText {
        text: qsTr("Paired devices")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        font.weight: Font.DemiBold
        visible: pairedRepeater.count > 0
    }

    Repeater {
        id: pairedRepeater

        model: BluetoothServices.pairedDevices

        delegate: BluetoothDeviceDelegate {
            required property var modelData

            device: modelData
            showForgetAction: true
            onPrimaryAction: modelData.connected ? modelData.disconnect() : modelData.connect()
            onForgetAction: modelData.forget()
        }
    }

    StyledText {
        visible: pairedRepeater.count === 0
        text: qsTr("No paired devices")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        Layout.alignment: Qt.AlignHCenter
    }
}
