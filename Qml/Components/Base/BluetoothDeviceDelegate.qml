pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ClippingWrapperRectangle {
    id: root

    required property var device

    property bool         showBlockAction: false
    property bool         showForgetAction: false
    property bool         showPairActions: false

    signal                blockToggled
    signal                forgetAction
    signal                primaryAction
    signal                secondaryAction

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
    border.color: Colours.m3Colors.m3OutlineVariant
    border.width: device?.connected ? 1 : 0
    color: device?.connected ? Colours.m3Colors.m3PrimaryContainer : "transparent"
    margin: Appearance.margin.small
    radius: Appearance.rounding.large

    RowLayout {
        spacing: Appearance.spacing.small

        Rectangle {
            Layout.preferredHeight: 36
            Layout.preferredWidth: 36
            color: root.device?.connected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
            radius: Appearance.rounding.small

            Icon {
                anchors.centerIn: parent
                color: root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                icon: root.device?.connected ? "bluetooth_connected" : root.device?.pairing ? "bluetooth_searching" : "bluetooth"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                color: root.device?.connected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
                text: BluetoothServices.displayName(root.device)
            }

            StyledText {
                color: root.device?.connected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                text: BluetoothServices.stateString(root.device)
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.small
                text: BluetoothServices.addressLine(root.device) + (root.device?.batteryAvailable ? ` · ${Math.round(root.device.battery * 100)}%` : "")
                visible: !!root.device?.address
            }
        }

        FloatingButton {
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            enabled: !root.showPairActions || !root.device?.pairing
            icon.color: root.showPairActions ? Colours.m3Colors.m3OnSurfaceVariant : root.showBlockAction ? (root.device?.blocked ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant) : (root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant)
            icon.name: root.showPairActions ? (root.device?.pairing ? "close" : "bluetooth") : root.showBlockAction ? "block" : (root.device?.connected ? "link_off" : "link")
            implicitHeight: 32
            implicitWidth: 32
            onClicked: {
                if (root.showBlockAction && !root.showPairActions)
                    root.blockToggled();
                else
                    root.primaryAction();
            }
        }

        Loader {
            active: root.showPairActions && (root.device?.pairing ?? false)
            visible: active
            sourceComponent: FloatingButton {
                backgroundRadius: Appearance.rounding.normal
                color: "transparent"
                icon.name: "close"
                implicitHeight: 32
                implicitWidth: 32
                onClicked: root.secondaryAction()
            }
        }

        Loader {
            active: root.showForgetAction
            visible: active
            sourceComponent: FloatingButton {
                backgroundRadius: Appearance.rounding.normal
                color: "transparent"
                icon.color: root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "delete"
                implicitHeight: 32
                implicitWidth: 32
                onClicked: root.forgetAction()
            }
        }
    }
}
