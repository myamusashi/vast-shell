import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "../Components"

Item {
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
                    id: passwordHotspotInput
                    text: Hotspot.password
                    placeHolderText: qsTr("Default: password123")
                    passwordMode: true
                    toggleButtonVisible: true
                    enabled: !Hotspot.isActive
                    opacity: enabled ? 1.0 : 0.5
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
        }

        SettingsCard {
            title: qsTr("Ethernet")
        }

        Item {
            Layout.fillHeight: true
        }
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
