pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Networking

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

    property color target: network.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"

    BlendColor {
        host: root
        target: root.target
    }

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    color: "transparent"
    radius: Appearance.rounding.large
    margin: Appearance.margin.small

    TapHandler {
        id: networkTap

        onTapped: root.tryConnect()
    }

    function tryConnect() {
        WifiUtils.tryConnect(root.network, net => root.pskDialog.show(net));
    }

    Connections {
        target: root.network

        function onConnectionFailed(reason) {
            WifiUtils.handleConnectionFailed(root.network, reason, net => root.pskDialog.show(net));
        }
    }

    RowLayout {
        spacing: Appearance.spacing.small

        Item {
            implicitWidth: 28
            implicitHeight: 28

            Icon {
                anchors.fill: parent
                icon: "signal_wifi_0_bar"
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            Icon {
                anchors.fill: parent
                icon: WifiUtils.iconFor(root.network?.signalStrength ?? 0, root.network ? !root.network.known : false)
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small * 0.5

            StyledText {
                Layout.fillWidth: true
                text: root.network?.name ?? ""
                elide: Text.ElideRight
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
            }

            StyledText {
                text: ConnectionState.toString(root.network.state)
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
            }
        }

        FloatingButton {
            implicitWidth: 28
            implicitHeight: 28
            backgroundRadius: Appearance.rounding.normal
            icon.name: root.network?.connected ? "link_off" : "wifi_add"
            icon.color: root.network?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            icon.size: Appearance.fonts.size.large * 1.5
            color: "transparent"
            onClicked: root.network?.connected ? root.network.disconnect() : root.tryConnect()
        }

        FloatingButton {
            implicitWidth: 28
            implicitHeight: 28
            backgroundRadius: Appearance.rounding.normal
            icon.name: "delete"
            icon.color: root.network?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
            icon.size: Appearance.fonts.size.large * 1.5
            color: "transparent"
            onClicked: root.network?.forget()
        }
    }
}
