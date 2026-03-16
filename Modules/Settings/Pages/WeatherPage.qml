import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base
import qs.Services

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
        spacing: Appearance.spacing.large

        StyledText {
            text: qsTr("Weather & Location")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("Geographic Data")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Latitude:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledTextInput {
                    text: Configs.weather.latitude
                    onTextChanged: Configs.weather.latitude = text
                    Layout.preferredWidth: 250
                    placeHolderText: "e.g., -6.200000"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Longitude:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledTextInput {
                    text: Configs.weather.longitude
                    onTextChanged: Configs.weather.longitude = text
                    Layout.preferredWidth: 250
                    placeHolderText: "e.g., 106.816666"
                }
            }
        }

        SettingsCard {
            title: qsTr("Sync & Overview")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Enable Quick Summary Widget:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSwitch {
                    checked: Configs.weather.enableQuickSummary
                    onCheckedChanged: Configs.weather.enableQuickSummary = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Weather Reload Time (ms):")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledTextInput {
                    text: Configs.weather.reloadTime.toString()
                    onTextChanged: {
                        var parsed = parseInt(text);
                        if (!isNaN(parsed) && parsed > 0) {
                            Configs.weather.reloadTime = parsed;
                        }
                    }
                    Layout.preferredWidth: 200
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
