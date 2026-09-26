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
    property bool showPairActions: false
    property bool showForgetAction: false
    property bool showBlockAction: false

    signal primaryAction
    signal secondaryAction
    signal forgetAction
    signal blockToggled

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    radius: Appearance.rounding.large
    margin: Appearance.margin.small
    color: "transparent"

    property color target: root.device?.connected ? Colours.m3Colors.m3PrimaryContainer : "transparent"

    BlendColor {
        host: root
        target: root.target
    }
    border.width: root.device?.connected ? 1 : 0
    border.color: Colours.m3Colors.m3OutlineVariant

    RowLayout {
        spacing: Appearance.spacing.small

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Appearance.rounding.small
            color: root.device?.connected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)

            Icon {
                anchors.centerIn: parent
                icon: root.device?.connected ? "bluetooth_connected" : root.device?.pairing ? "bluetooth_searching" : "bluetooth"
                color: root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: BluetoothServices.displayName(root.device)
                elide: Text.ElideRight
                color: root.device?.connected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
            }

            StyledText {
                text: BluetoothServices.stateString(root.device)
                color: root.device?.connected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
            }

            StyledText {
                visible: !!root.device?.address
                text: BluetoothServices.addressLine(root.device) + (root.device?.batteryAvailable ? ` · ${Math.round(root.device.battery * 100)}%` : "")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        FloatingButton {
            visible: root.showPairActions
            implicitWidth: 32
            implicitHeight: 32
            backgroundRadius: Appearance.rounding.normal
            icon.name: root.device?.pairing ? "close" : "bluetooth"
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            color: "transparent"
            enabled: !root.device?.pairing
            onClicked: root.primaryAction()
        }

        FloatingButton {
            visible: root.showPairActions && root.device?.pairing
            implicitWidth: 32
            implicitHeight: 32
            backgroundRadius: Appearance.rounding.normal
            icon.name: "close"
            color: "transparent"
            onClicked: root.secondaryAction()
        }

        FloatingButton {
            visible: !root.showPairActions && !root.showBlockAction
            implicitWidth: 32
            implicitHeight: 32
            backgroundRadius: Appearance.rounding.normal
            icon.name: root.device?.connected ? "link_off" : "link"
            icon.color: root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            color: "transparent"
            onClicked: root.primaryAction()
        }

        FloatingButton {
            visible: root.showBlockAction
            implicitWidth: 32
            implicitHeight: 32
            backgroundRadius: Appearance.rounding.normal
            icon.name: "block"
            icon.color: root.device?.blocked ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
            color: "transparent"
            onClicked: root.blockToggled()
        }

        FloatingButton {
            visible: root.showForgetAction
            implicitWidth: 32
            implicitHeight: 32
            backgroundRadius: Appearance.rounding.normal
            icon.name: "delete"
            icon.color: root.device?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            color: "transparent"
            onClicked: root.forgetAction()
        }
    }
}
