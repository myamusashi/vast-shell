pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

ColumnLayout {
    spacing: Appearance.spacing.small * 0.5
    visible: BluetoothServices.adapterEnabled

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            text: qsTr("Available devices")
        }
        FloatingButton {
            backgroundRadius: Appearance.rounding.small
            color: "transparent"
            enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.name: "refresh"
            implicitHeight: 28
            implicitWidth: 28
            spinning: BluetoothServices.isDiscovering

            onClicked: {
                if (BluetoothServices.isDiscovering)
                    BluetoothServices.setDiscovering(false);
                else
                    BluetoothServices.setDiscovering(true);
            }
        }
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
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        text: qsTr("Searching for devices…")
        visible: availableRepeater.count === 0 && BluetoothServices.isDiscovering
    }
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        text: qsTr("No new devices — turn on scanning")
        visible: availableRepeater.count === 0 && !BluetoothServices.isDiscovering && BluetoothServices.hasPaired
    }
}
