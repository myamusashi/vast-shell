pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell.Networking

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

WrapperRectangle {
    id: root

    readonly property bool scanner: Wifi.activeWifiDevice.scannerEnabled

    property bool isVisible: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2

    border {
        width: 1
        color: Colours.m3Colors.m3Outline
    }
    implicitWidth: parent.width * 0.8
    implicitHeight: Math.min(loader.implicitHeight + 20 * 2, parent.height * 0.8)
    margin: Appearance.margin.normal
    radius: Appearance.rounding.small
    color: Colours.m3Colors.m3SurfaceContainer
    scale: isVisible ? 1.0 : 0.5
    opacity: isVisible ? 1.0 : 0.0
    transformOrigin: Item.Center

    transform: Translate {
        x: root.isVisible ? 0 : root.zoomOriginX - root.width / 2
        y: root.isVisible ? 0 : root.zoomOriginY - root.height / 2

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on y {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        id: loader

        active: true
        asynchronous: true
        sourceComponent: ColumnLayout {
            width: loader.width
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Internet")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Tap/click a network to connect")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.medium
                font.weight: Font.DemiBold
            }

            Item {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredHeight: 5

                StyledRect {
                    anchors.centerIn: parent
                    implicitWidth: parent.width * 0.5
                    implicitHeight: 4
                    color: Colours.m3Colors.m3SurfaceContainerHighest
                }

                Progress {
                    anchors.centerIn: parent
                    implicitWidth: parent.width * 0.5
                    implicitHeight: 4
                    condition: Wifi.activeWifiDevice.scannerEnabled && Networking.wifiEnabled && root.isVisible
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Wi-Fi")
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledSwitch {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    checked: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = checked
                }
            }

            ListView {
                id: devicesListView

                Layout.fillWidth: true
                implicitHeight: contentHeight
                interactive: false
                model: Networking.devices
                spacing: Appearance.spacing.small

                delegate: ColumnLayout {
                    id: deviceDelegate

                    required property WifiDevice modelData

                    width: devicesListView.width

                    Repeater {
                        model: {
                            if (deviceDelegate.modelData.type !== DeviceType.Wifi)
                                return [];
                            return [...deviceDelegate.modelData.networks.values].sort((a, b) => {
                                if (a.connected !== b.connected)
                                    return b.connected - a.connected;
                                return b.signalStrength - a.signalStrength;
                            });
                        }

                        delegate: WrapperRectangle {
                            id: networkDelegate

                            required property WifiNetwork modelData

                            Layout.fillWidth: true
                            color: networkDelegate.modelData.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
                            radius: Appearance.rounding.large
                            margin: Appearance.margin.small

                            Behavior on color {
                                CAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }

                            TapHandler {
                                id: networkTap

                                onTapped: {
                                    if (!networkDelegate.modelData.connected)
                                        networkDelegate.modelData.connect();
                                }
                            }

                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: contextMenu.popup()
                            }

                            Menu {
                                id: contextMenu

                                modal: true
                                focus: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                                MenuItem {
                                    text: networkDelegate.modelData.connected ? qsTr("Disconnect") : qsTr("Connect")
                                    onTriggered: {
                                        if (networkDelegate.modelData.connected)
                                            networkDelegate.modelData.disconnect();
                                        else
                                            networkDelegate.modelData.connect();
                                    }
                                }

                                MenuItem {
                                    text: qsTr("Forget Network")
                                    onTriggered: networkDelegate.modelData.forget()
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
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.large * 1.5
                                    }

                                    Icon {
                                        anchors.fill: parent
                                        icon: Wifi.getWiFiIcon(networkDelegate.modelData.signalStrength)
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.large * 1.5
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.small * 0.5

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: networkDelegate.modelData.name
                                        elide: Text.ElideRight
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.normal
                                    }

                                    StyledText {
                                        text: ({
                                                [NetworkState.Connected]: qsTr("Connected"),
                                                [NetworkState.Disconnected]: qsTr("Disconnected"),
                                                [NetworkState.Disconnecting]: qsTr("Disconnecting"),
                                                [NetworkState.Connecting]: qsTr("Connecting"),
                                                [NetworkState.Unknown]: qsTr("Unknown")
                                            })[networkDelegate.modelData.state] ?? qsTr("Unknown")
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.small
                                    }
                                }

                                Icon {
                                    visible: !networkDelegate.modelData.known
                                    icon: "lock"
                                    color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Wifi.activeWifiDevice.scannerEnabled = true;
    }
}
