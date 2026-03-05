pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Networking

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

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
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentColumn

                width: parent.width
                spacing: Appearance.spacing.normal

                // ── Hotspot ────────────────────────────────────────
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

                    LabeledRow {
                        label: qsTr("Enable hotspot & sharing internet:")

                        StyledSwitch {
                            Layout.alignment: Qt.AlignRight
                            checked: Hotspot.isActive
                            enabled: Hotspot.status !== Hotspot.Status.Starting && Hotspot.status !== Hotspot.Status.Stopping
                            onCheckedChanged: Hotspot.toggle()
                        }
                    }

                    LabeledRow {
                        label: qsTr("User hotspot:")

                        StyledTextInput {
                            text: Hotspot.ssid
                            placeHolderText: qsTr("Default: MyHotspot")
                            passwordMode: false
                            toggleButtonVisible: false
                            enabled: !Hotspot.isActive
                            opacity: enabled ? 1.0 : 0.5
                        }
                    }

                    LabeledRow {
                        label: qsTr("Password hotspot:")

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

                    LabeledRow {
                        label: qsTr("Hotspot interface:")

                        StyledTextInput {
                            text: Hotspot.hotspotInterface
                            placeHolderText: qsTr("Default: %1").arg(Hotspot.hotspotInterface || qsTr("none detected"))
                            passwordMode: false
                            toggleButtonVisible: false
                        }
                    }

                    LabeledRow {
                        label: qsTr("Bandwidth:")

                        StyledComboBox {
                            implicitWidth: 240
                            currentIndex: -1
                            model: [
                                {
                                    display: "bg (2.4 GHz)"
                                },
                                {
                                    display: "a (5 GHz)"
                                }
                            ]
                            onActivated: Hotspot.band = currentIndex === 0 ? "bg" : "a"
                        }
                    }

                    StyledButton {
                        Layout.alignment: Qt.AlignRight
                        text: "Apply"
                        textColor: Colours.m3Colors.m3OnPrimary
                        color: Colours.m3Colors.m3Primary
                        onClicked: Hotspot.toggle()
                    }
                }

                SettingsCard {
                    title: qsTr("Wi-Fi")

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Enable Wi-Fi:")
                            font.pixelSize: Appearance.fonts.size.large
                            color: Colours.m3Colors.m3OnSurfaceVariant
                        }

                        StyledSwitch {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 32
                            checked: Networking.wifiEnabled
                            onToggled: Networking.wifiEnabled = checked
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5

                        StyledRect {
                            anchors.centerIn: parent
                            implicitWidth: parent.width
                            implicitHeight: 4
                            color: Colours.m3Colors.m3SurfaceContainerHighest
                        }

                        Progress {
                            anchors.centerIn: parent
                            implicitWidth: parent.width
                            implicitHeight: 4
                            condition: Wifi.activeWifiDevice?.scannerEnabled && Networking.wifiEnabled
                        }
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

                            required property WifiDevice modelData

                            width: wifiListView.width

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
                                    color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
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
                                            if (networkDelegate.modelData && !networkDelegate.modelData.connected)
                                                networkDelegate.modelData.connect();
                                        }
                                    }

                                    TapHandler {
                                        acceptedButtons: Qt.RightButton
                                        onTapped: wifiContextMenu.popup()
                                    }

                                    StyledMenu {
                                        id: wifiContextMenu

                                        StyledMenuItem {
                                            text: networkDelegate.modelData?.connected ? qsTr("Disconnect") : qsTr("Connect")
                                            onTriggered: networkDelegate.modelData?.connected ? networkDelegate.modelData.disconnect() : networkDelegate.modelData?.connect()
                                        }

                                        StyledMenuItem {
                                            text: qsTr("Forget Network")
                                            onTriggered: networkDelegate.modelData?.forget()
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
                                                color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                                font.pixelSize: Appearance.fonts.size.large * 1.5
                                            }

                                            Icon {
                                                anchors.fill: parent
                                                icon: Wifi.getWiFiIcon(networkDelegate.modelData?.signalStrength ?? 0)
                                                color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
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
                                                color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                                font.pixelSize: Appearance.fonts.size.normal
                                            }

                                            StyledText {
                                                text: ({
                                                        [NetworkState.Connected]: qsTr("Connected"),
                                                        [NetworkState.Disconnected]: qsTr("Disconnected"),
                                                        [NetworkState.Disconnecting]: qsTr("Disconnecting"),
                                                        [NetworkState.Connecting]: qsTr("Connecting"),
                                                        [NetworkState.Unknown]: qsTr("Unknown")
                                                    })[networkDelegate.modelData?.state] ?? qsTr("Unknown")
                                                color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                                font.pixelSize: Appearance.fonts.size.small
                                            }
                                        }

                                        Icon {
                                            visible: networkDelegate.modelData && !networkDelegate.modelData.known
                                            icon: "lock"
                                            color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                            font.pixelSize: Appearance.fonts.size.normal
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

    Component.onCompleted: {
        if (Wifi.activeWifiDevice)
            Wifi.activeWifiDevice.scannerEnabled = true;
    }

    component LabeledRow: RowLayout {
        Layout.fillWidth: true
        required property string label

        StyledText {
            Layout.fillWidth: true
            text: parent.label
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }
}
