pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Button
import qs.Components.Effects
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

WrapperRectangle {
    id: root

    required property var network
    required property var pskDialog

    property color        target: network.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"

    function              tryConnect() {
        WifiUtils.tryConnect(root.network, net => root.pskDialog.show(net));
    }

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
    color: "transparent"
    margin: Appearance.margin.small
    radius: Appearance.rounding.large

    BlendColor {
        host: root
        target: root.target
    }

    TapHandler {
        id: networkTap

        onTapped: root.tryConnect()
    }

    Connections {
        function onConnectionFailed(reason) {
            WifiUtils.handleConnectionFailed(root.network, reason, net => root.pskDialog.show(net));
        }

        target: root.network
    }

    RowLayout {
        spacing: Appearance.spacing.small

        Item {
            implicitHeight: 28
            implicitWidth: 28

            Icon {
                anchors.fill: parent
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                icon: "signal_wifi_0_bar"
            }

            Icon {
                anchors.fill: parent
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                icon: WifiUtils.iconFor(root.network?.signalStrength ?? 0, root.network ? !root.network.known : false)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small * 0.5

            StyledText {
                Layout.fillWidth: true
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                text: root.network?.name ?? ""
            }

            StyledText {
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: ConnectionState.toString(root.network.state)
            }
        }

        FloatingButton {
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            icon.color: root.network?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            icon.name: root.network?.connected ? "link_off" : "wifi_add"
            icon.size: Appearance.fonts.size.large * 1.5
            implicitHeight: 28
            implicitWidth: 28
            onClicked: root.network?.connected ? root.network.disconnect() : root.tryConnect()
        }

        FloatingButton {
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            icon.color: root.network?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            icon.name: "delete"
            icon.size: Appearance.fonts.size.large * 1.5
            implicitHeight: 28
            implicitWidth: 28
            onClicked: root.network?.forget()
        }
    }
}
