pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

ColumnLayout {
    visible: BluetoothServices.adapterEnabled
    spacing: Appearance.spacing.small * 0.5

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Available devices")
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
        }

        FloatingButton {
            implicitWidth: 28
            implicitHeight: 28
            backgroundRadius: Appearance.rounding.small
            enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
            spinning: BluetoothServices.isDiscovering
            icon.name: "refresh"
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            color: "transparent"
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
        visible: availableRepeater.count === 0 && BluetoothServices.isDiscovering
        text: qsTr("Searching for devices…")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        Layout.alignment: Qt.AlignHCenter
    }

    StyledText {
        visible: availableRepeater.count === 0 && !BluetoothServices.isDiscovering && BluetoothServices.hasPaired
        text: qsTr("No new devices — turn on scanning")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        Layout.alignment: Qt.AlignHCenter
    }
}
