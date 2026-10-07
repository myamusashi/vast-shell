pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Feedback
import qs.Core.Configs
import qs.Services

ColumnLayout {
    id: root

    required property bool isVisible

    spacing: Appearance.spacing.small

    Progress {
        Layout.fillWidth: true
        condition: BluetoothServices.isDiscovering && root.isVisible
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Bluetooth")
        }

        Item {
            Layout.fillWidth: true
        }

        StyledSwitch {
            Layout.preferredHeight: 32
            Layout.preferredWidth: 52
            checked: BluetoothServices.adapterEnabled
            enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
            onToggled: BluetoothServices.setEnabled(checked)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: BluetoothServices.adapterAvailable && BluetoothServices.adapterEnabled

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Discoverable")
        }

        Item {
            Layout.fillWidth: true
        }

        StyledSwitch {
            Layout.preferredHeight: 32
            Layout.preferredWidth: 52
            checked: BluetoothServices.discoverable
            onToggled: BluetoothServices.setDiscoverable(checked)
        }
    }
}
