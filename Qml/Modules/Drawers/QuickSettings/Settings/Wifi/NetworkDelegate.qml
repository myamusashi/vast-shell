pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Button
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ClippingWrapperRectangle {
    id: root

    required property var network
    required property var pskDialog

    function              tryConnect() {
        WifiUtils.tryConnect(root.network, targetNetwork => root.pskDialog.show(targetNetwork));
    }

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
    color: network.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
    margin: Appearance.margin.small
    radius: Appearance.rounding.large

    TapHandler {
        id: networkTap

        onTapped: root.tryConnect()
    }

    Connections {

        function onConnectionFailed(reason) {
            WifiUtils.handleConnectionFailed(root.network, reason, targetNetwork => root.pskDialog.show(targetNetwork));
        }

        target: root.network
    }

    RowLayout {
        spacing: Appearance.spacing.small

        Item {
            id: signalIcon

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

            Tooltip {
                anchorItem: signalIcon
                text: qsTr("Signal: %1%").arg(Math.round((root.network?.signalStrength ?? 0) * 100))
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small * 0.5

            StyledText {
                id: ssidText

                Layout.fillWidth: true
                color: root.network.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                text: root.network?.name ?? ""

                Tooltip {
                    anchorItem: ssidText
                    enabled: ssidText.truncated
                    text: ssidText.text
                }
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
            tooltipText: root.network?.connected ? qsTr("Disconnect") : qsTr("Connect")
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
            tooltipText: qsTr("Forget network")
            onClicked: root.network?.forget()
        }
    }
}
