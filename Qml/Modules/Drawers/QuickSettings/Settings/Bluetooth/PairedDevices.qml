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
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        font.weight: Font.DemiBold
        text: qsTr("Paired devices")
        visible: pairedRepeater.count > 0
    }

    Repeater {
        id: pairedRepeater

        model: BluetoothServices.pairedDevices
        delegate: BluetoothDeviceDelegate {
            required property var modelData

            device: modelData
            showForgetAction: true
            onForgetAction: modelData.forget()
            onPrimaryAction: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        text: qsTr("No paired devices")
        visible: pairedRepeater.count === 0
    }
}
