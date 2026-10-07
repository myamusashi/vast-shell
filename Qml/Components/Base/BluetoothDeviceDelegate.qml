pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Effects
import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

WrapperRectangle {
    id: root

    required property var device

    property bool         showBlockAction: false
    property bool         showForgetAction: false
    property bool         showPairActions: false
    property color        target: root.device?.connected ? Colours.m3Colors.m3PrimaryContainer : "transparent"

    signal                blockToggled
    signal                forgetAction
    signal                primaryAction
    signal                secondaryAction

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
    border.color: Colours.m3Colors.m3OutlineVariant
    border.width: root.device?.connected ? 1 : 0
    color: "transparent"
    margin: Appearance.margin.small
    radius: Appearance.rounding.large

    BlendColor {
        host: root
        target: root.target
    }

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
            enabled: !root.device?.pairing
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.name: root.device?.pairing ? "close" : "bluetooth"
            implicitHeight: 32
            implicitWidth: 32
            visible: root.showPairActions
            onClicked: root.primaryAction()
        }

        FloatingButton {
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            icon.name: "close"
            implicitHeight: 32
            implicitWidth: 32
            visible: root.showPairActions && root.device?.pairing
            onClicked: root.secondaryAction()
        }

        FloatingButton {
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            icon.color: root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            icon.name: root.device?.connected ? "link_off" : "link"
            implicitHeight: 32
            implicitWidth: 32
            visible: !root.showPairActions && !root.showBlockAction
            onClicked: root.primaryAction()
        }

        FloatingButton {
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            icon.color: root.device?.blocked ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
            icon.name: "block"
            implicitHeight: 32
            implicitWidth: 32
            visible: root.showBlockAction
            onClicked: root.blockToggled()
        }

        FloatingButton {
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            icon.color: root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            icon.name: "delete"
            implicitHeight: 32
            implicitWidth: 32
            visible: root.showForgetAction
            onClicked: root.forgetAction()
        }
    }
}
