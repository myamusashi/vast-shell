pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking

import qs.Components.Feedback
import qs.Components.Base
import qs.Components.Button
import qs.Components.Dialog
import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States
import qs.Services
import qs.Components.Effects

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    WifiPskDialog {
        id: wifiPskDialog
    }

    CardRevealer {
        id: cardRevealer

        container: contentColumn
        target: pageFlickable
    }

    function revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.margin.large
        }
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.bottomMargin: Appearance.margin.normal
            text: qsTr("Network & Internet")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
        }

        Flickable {
            id: pageFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentColumn

                width: parent.width
                spacing: Appearance.spacing.normal

                SettingsCard {
                    title: qsTr("Hotspot")

                    Progress {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        condition: Hotspot.status === Hotspot.Status.Starting || Hotspot.status === Hotspot.Status.Stopping
                    }

                    StyledText {
                        visible: Hotspot.errorMessage !== ""
                        text: Hotspot.errorMessage
                        color: Colours.m3Colors.m3Error
                    }

                    SettingRow {
                        label: qsTr("Enable hotspot & sharing internet:")
                        description: qsTr("Toggle Wi-Fi hotspot and internet sharing.")

                        StyledSwitch {
                            Layout.alignment: Qt.AlignRight
                            checked: Hotspot.isActive
                            enabled: Hotspot.status !== Hotspot.Status.Starting && Hotspot.status !== Hotspot.Status.Stopping
                            onToggled: Hotspot.toggle()
                        }
                    }

                    GridLayout {
                        columns: 2

                        SettingRow {
                            label: qsTr("User hotspot:")
                            description: qsTr("SSID broadcast name for the hotspot.")

                            StyledTextInput {
                                text: Hotspot.ssid
                                placeHolderText: qsTr("Default: MyHotspot")
                                passwordMode: false
                                toggleButtonVisible: false
                                enabled: !Hotspot.isActive
                                opacity: enabled ? 1.0 : 0.5
                                onTextChanged: Hotspot.ssid = text
                            }
                        }

                        SettingRow {
                            label: qsTr("Password hotspot:")
                            description: qsTr("Password required.")

                            StyledTextInput {
                                text: Hotspot.password
                                placeHolderText: qsTr("Default: password123")
                                passwordMode: true
                                toggleButtonVisible: true
                                enabled: !Hotspot.isActive
                                opacity: enabled ? 1.0 : 0.5
                                onTextChanged: Hotspot.password = text
                            }
                        }

                        SettingRow {
                            label: qsTr("Hotspot interface:")
                            description: qsTr("Network interface used for hotspot sharing.")

                            StyledTextInput {
                                text: Hotspot.hotspotInterface
                                placeHolderText: qsTr("Default: %1").arg(Hotspot.hotspotInterface || qsTr("none detected"))
                                passwordMode: false
                                toggleButtonVisible: false
                                enabled: false
                                opacity: 0.7
                            }
                        }

                        SettingRow {
                            label: qsTr("Bandwidth:")
                            description: qsTr("Wi-Fi band for the hotspot.")

                            SplitButton {
                                readonly property int selectedIndex: Hotspot.band === "a" ? 1 : 0

                                model: [
                                    {
                                        display: "bg (2.4 GHz)"
                                    },
                                    {
                                        display: "a (5 GHz)"
                                    }
                                ]
                                textRole: "display"
                                currentIndex: selectedIndex
                                text: model[selectedIndex]?.display ?? "bg (2.4 GHz)"
                                icon.name: "graphic_eq"

                                onMenuItemActivated: index => Hotspot.band = index === 0 ? "bg" : "a"
                            }
                        }
                    }

                    ExtendedFloatingButton {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Apply && Restart")
                        textColor: Colours.m3Colors.m3OnPrimary
                        color: Colours.m3Colors.m3Primary
                        onClicked: {
                            if (Hotspot.isActive) {
                                Hotspot.stop();
                                Qt.callLater(function () {
                                    Qt.callLater(Hotspot.start);
                                });
                            } else {
                                Hotspot.start();
                            }
                        }
                    }
                }

                SettingsCard {
                    title: qsTr("Wi-Fi")

                    SettingRow {
                        label: qsTr("Enable Wi-Fi:")
                        description: qsTr("Turn Wi-Fi scanning and connections.")

                        StyledSwitch {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 32
                            checked: Networking.wifiEnabled
                            onToggled: Qt.callLater(() => {
                                Networking.wifiEnabled = checked;
                            })
                        }
                    }

                    Progress {
                        Layout.fillWidth: true
                        condition: GlobalStates.isWifiScannerOpen
                    }

                    ListView {
                        id: wifiListView

                        Layout.fillWidth: true
                        implicitHeight: contentHeight
                        interactive: false
                        model: Networking.devices
                        spacing: Appearance.spacing.small

                        delegate: ColumnLayout {
                            id: deviceDelegate

                            required property var modelData

                            width: wifiListView.width

                            Repeater {
                                model: ScriptModel {
                                    values: {
                                        if (deviceDelegate.modelData.type !== DeviceType.Wifi) // qmllint disable
                                            return [];
                                        return WifiUtils.sorted([...deviceDelegate.modelData.networks.values]);
                                    }
                                }

                                delegate: WrapperRectangle {
                                    id: networkDelegate

                                    property color target: modelData.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"

                                    BlendColor {
                                        host: networkDelegate
                                        target: networkDelegate.target
                                    }

                                    required property var modelData

                                    Layout.fillWidth: true
                                    radius: Appearance.rounding.large
                                    margin: Appearance.margin.small

                                    TapHandler {
                                        id: networkTap

                                        onTapped: networkDelegate.tryConnect()
                                    }

                                    function tryConnect() {
                                        WifiUtils.tryConnect(networkDelegate.modelData, net => wifiPskDialog.show(net));
                                    }

                                    Connections {
                                        target: networkDelegate.modelData
                                        function onConnectionFailed(reason) {
                                            WifiUtils.handleConnectionFailed(networkDelegate.modelData, reason, net => wifiPskDialog.show(net));
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
                                                icon: WifiUtils.iconFor(networkDelegate.modelData?.signalStrength ?? 0, networkDelegate.modelData ? !networkDelegate.modelData.known : false)
                                                color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                                font.pixelSize: Appearance.fonts.size.large * 1.5
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Appearance.spacing.small * 0.5

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: networkDelegate.modelData?.name ?? ""
                                                elide: Text.ElideRight
                                                color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                                font.pixelSize: Appearance.fonts.size.normal
                                            }

                                            StyledText {
                                                text: ConnectionState.toString(networkDelegate.modelData.state)
                                                color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                                font.pixelSize: Appearance.fonts.size.small
                                            }
                                        }

                                        FloatingButton {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            backgroundRadius: Appearance.rounding.normal
                                            icon.name: networkDelegate.modelData?.connected ? "link_off" : "wifi_add"
                                            icon.color: Colours.m3Colors.m3SurfaceVariant
                                            icon.size: Appearance.fonts.size.large * 1.5
                                            onClicked: networkDelegate.modelData?.connected ? networkDelegate.modelData.disconnect() : networkDelegate.tryConnect()
                                        }

                                        FloatingButton {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            backgroundRadius: Appearance.rounding.normal
                                            icon.name: "delete"
                                            icon.color: Colours.m3Colors.m3SurfaceVariant
                                            icon.size: Appearance.fonts.size.large * 1.5
                                            onClicked: networkDelegate.modelData?.forget()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
