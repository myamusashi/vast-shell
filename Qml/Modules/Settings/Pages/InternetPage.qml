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

    function revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
    }

    Layout.fillHeight: true
    Layout.fillWidth: true

    WifiPskDialog {
        id: wifiPskDialog
    }
    CardRevealer {
        id: cardRevealer

        container: contentColumn
        target: pageFlickable
    }
    ColumnLayout {
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            margins: Appearance.margin.large
        }
        StyledText {
            Layout.bottomMargin: Appearance.margin.normal
            color: Colours.m3Colors.m3OnSurface
            font.bold: true
            font.pixelSize: Appearance.fonts.size.extraLarge
            text: qsTr("Network & Internet")
        }
        Flickable {
            id: pageFlickable

            Layout.fillHeight: true
            Layout.fillWidth: true
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: contentColumn.implicitHeight

            ColumnLayout {
                id: contentColumn

                spacing: Appearance.spacing.normal
                width: parent.width

                SettingsCard {
                    title: qsTr("Hotspot")

                    Progress {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        condition: Hotspot.status === Hotspot.Status.Starting || Hotspot.status === Hotspot.Status.Stopping
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Error
                        text: Hotspot.errorMessage
                        visible: Hotspot.errorMessage !== ""
                    }
                    SettingRow {
                        description: qsTr("Toggle Wi-Fi hotspot and internet sharing.")
                        label: qsTr("Enable hotspot & sharing internet:")

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
                            description: qsTr("SSID broadcast name for the hotspot.")
                            label: qsTr("User hotspot:")

                            StyledTextInput {
                                enabled: !Hotspot.isActive
                                opacity: enabled ? 1.0 : 0.5
                                passwordMode: false
                                placeHolderText: qsTr("Default: MyHotspot")
                                text: Hotspot.ssid
                                toggleButtonVisible: false

                                onTextChanged: Hotspot.ssid = text
                            }
                        }
                        SettingRow {
                            description: qsTr("Password required.")
                            label: qsTr("Password hotspot:")

                            StyledTextInput {
                                enabled: !Hotspot.isActive
                                opacity: enabled ? 1.0 : 0.5
                                passwordMode: true
                                placeHolderText: qsTr("Default: password123")
                                text: Hotspot.password
                                toggleButtonVisible: true

                                onTextChanged: Hotspot.password = text
                            }
                        }
                        SettingRow {
                            description: qsTr("Network interface used for hotspot sharing.")
                            label: qsTr("Hotspot interface:")

                            StyledTextInput {
                                enabled: false
                                opacity: 0.7
                                passwordMode: false
                                placeHolderText: qsTr("Default: %1").arg(Hotspot.hotspotInterface || qsTr("none detected"))
                                text: Hotspot.hotspotInterface
                                toggleButtonVisible: false
                            }
                        }
                        SettingRow {
                            description: qsTr("Wi-Fi band for the hotspot.")
                            label: qsTr("Bandwidth:")

                            SplitButton {
                                readonly property int selectedIndex: Hotspot.band === "a" ? 1 : 0

                                currentIndex: selectedIndex
                                icon.name: "graphic_eq"
                                model: [
                                    {
                                        display: "bg (2.4 GHz)"
                                    },
                                    {
                                        display: "a (5 GHz)"
                                    }
                                ]
                                text: model[selectedIndex]?.display ?? "bg (2.4 GHz)"
                                textRole: "display"

                                onMenuItemActivated: index => Hotspot.band = index === 0 ? "bg" : "a"
                            }
                        }
                    }
                    ExtendedFloatingButton {
                        Layout.alignment: Qt.AlignRight
                        color: Colours.m3Colors.m3Primary
                        text: qsTr("Apply && Restart")
                        textColor: Colours.m3Colors.m3OnPrimary

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
                        description: qsTr("Turn Wi-Fi scanning and connections.")
                        label: qsTr("Enable Wi-Fi:")

                        StyledSwitch {
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: 52
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
                                delegate: WrapperRectangle {
                                    id: networkDelegate

                                    required property var modelData
                                    property color target: modelData.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"

                                    function tryConnect() {
                                        WifiUtils.tryConnect(networkDelegate.modelData, net => wifiPskDialog.show(net));
                                    }

                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    color: "transparent"
                                    margin: Appearance.margin.small
                                    radius: Appearance.rounding.large

                                    TapHandler {
                                        id: networkTap

                                        onTapped: networkDelegate.tryConnect()
                                    }
                                    BlendColor {
                                        host: networkDelegate
                                        target: networkDelegate.target
                                    }
                                    Connections {
                                        function onConnectionFailed(reason) {
                                            WifiUtils.handleConnectionFailed(networkDelegate.modelData, reason, net => wifiPskDialog.show(net));
                                        }

                                        target: networkDelegate.modelData
                                    }
                                    RowLayout {
                                        spacing: Appearance.spacing.small

                                        Item {
                                            implicitHeight: 28
                                            implicitWidth: 28

                                            Icon {
                                                anchors.fill: parent
                                                color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                                font.pixelSize: Appearance.fonts.size.large * 1.5
                                                icon: "signal_wifi_0_bar"
                                            }
                                            Icon {
                                                anchors.fill: parent
                                                color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                                font.pixelSize: Appearance.fonts.size.large * 1.5
                                                icon: WifiUtils.iconFor(networkDelegate.modelData?.signalStrength ?? 0, networkDelegate.modelData ? !networkDelegate.modelData.known : false)
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Appearance.spacing.small * 0.5

                                            StyledText {
                                                Layout.fillWidth: true
                                                color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                                elide: Text.ElideRight
                                                font.pixelSize: Appearance.fonts.size.normal
                                                text: networkDelegate.modelData?.name ?? ""
                                            }
                                            StyledText {
                                                color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                                font.pixelSize: Appearance.fonts.size.small
                                                text: ConnectionState.toString(networkDelegate.modelData.state)
                                            }
                                        }
                                        FloatingButton {
                                            backgroundRadius: Appearance.rounding.normal
                                            icon.color: Colours.m3Colors.m3SurfaceVariant
                                            icon.name: networkDelegate.modelData?.connected ? "link_off" : "wifi_add"
                                            icon.size: Appearance.fonts.size.large * 1.5
                                            implicitHeight: 28
                                            implicitWidth: 28

                                            onClicked: networkDelegate.modelData?.connected ? networkDelegate.modelData.disconnect() : networkDelegate.tryConnect()
                                        }
                                        FloatingButton {
                                            backgroundRadius: Appearance.rounding.normal
                                            icon.color: Colours.m3Colors.m3SurfaceVariant
                                            icon.name: "delete"
                                            icon.size: Appearance.fonts.size.large * 1.5
                                            implicitHeight: 28
                                            implicitWidth: 28

                                            onClicked: networkDelegate.modelData?.forget()
                                        }
                                    }
                                }
                                model: ScriptModel {
                                    values: {
                                        if (deviceDelegate.modelData.type !== DeviceType.Wifi) // qmllint disable
                                            return [];
                                        return WifiUtils.sorted([...deviceDelegate.modelData.networks.values]);
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
