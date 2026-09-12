pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Networking
import Vast.Utils

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

WrapperRectangle {
    id: root

    required property var network
    required property var pskDialog

    property color target: network.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
    onTargetChanged: {
        colorBlendAnim.stop();
        colorFrom = color;
        colorTo = target;
        colorBlending = true;
        colorBlendProgress = 0.0;
        colorBlendAnim.start();
    }

    property color colorFrom
    property color colorTo
    property bool colorBlending: false
    property real colorBlendProgress: 1.0

    onColorBlendProgressChanged: {
        if (!colorBlending)
            return;
        if (colorBlendProgress >= 1) {
            color = colorTo;
            colorBlending = false;
        } else if (colorBlendProgress > 0) {
            color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
        }
    }

    NAnim {
        id: colorBlendAnim
        target: root
        property: "colorBlendProgress"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.small
    }

    Layout.fillWidth: true
    radius: Appearance.rounding.large
    margin: Appearance.margin.small

    TapHandler {
        id: networkTap

        onTapped: root.tryConnect()
    }

    function tryConnect() {
        const net = root.network;
        if (!net || net.connected)
            return;
        if (net.known || net.security === WifiSecurityType.Open)
            net.connect();
        else
            root.pskDialog.show(net);
    }

    Connections {
        target: root.network

        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets)
                root.pskDialog.show(root.network);
        }
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Appearance.margin.small
        }
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
                icon: {
                    const p = Math.round((root.network?.signalStrength ?? 0) * 100);
                    if (p >= 80)
                        return root.network && !root.network.known ? "network_wifi_locked" : "network_wifi";
                    if (p >= 50)
                        return root.network && !root.network.known ? "network_wifi_3_bar_locked" : "network_wifi_3_bar";
                    if (p >= 30)
                        return root.network && !root.network.known ? "network_wifi_2_bar_locked" : "network_wifi_2_bar";
                    if (p >= 15)
                        return root.network && !root.network.known ? "network_wifi_1_bar_locked" : "network_wifi_1_bar";
                    return "signal_wifi_0_bar";
                }
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
