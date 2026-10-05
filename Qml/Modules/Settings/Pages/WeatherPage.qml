import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base
import qs.Services

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Weather & Location")

    SettingsCard {
        title: qsTr("Geographic Data")

        SettingRow {
            description: qsTr("Latitude of your location for weather and astronomy data.")
            label: qsTr("Latitude:")

            StyledTextInput {
                Layout.preferredWidth: 250
                placeHolderText: "e.g., -6.200000"
                text: Configs.weather.latitude
                toggleButtonVisible: false

                onTextChanged: Configs.weather.latitude = text
            }
        }
        SettingRow {
            description: qsTr("Longitude of your location for weather and astronomy data.")
            label: qsTr("Longitude:")

            StyledTextInput {
                Layout.preferredWidth: 250
                placeHolderText: "e.g., 106.816666"
                text: Configs.weather.longitude
                toggleButtonVisible: false

                onTextChanged: Configs.weather.longitude = text
            }
        }
    }
    SettingsCard {
        title: qsTr("Astronomy API")

        SettingRow {
            description: qsTr("API key from WeatherAPI.com for astronomy and forecast data.")
            label: qsTr("WeatherAPI.com Key:")

            StyledTextInput {
                Layout.preferredWidth: 300
                placeHolderText: qsTr("Enter your WeatherAPI.com API key")
                text: Configs.weather.astronomyApiKey
                toggleButtonVisible: false

                onTextChanged: Configs.weather.astronomyApiKey = text
            }
        }
    }
    SettingsCard {
        title: qsTr("Sync & Overview")

        SettingRow {
            description: qsTr("Show a compact weather summary in quick settings.")
            label: qsTr("Enable Quick Summary Widget:")

            StyledSwitch {
                checked: Configs.weather.enableQuickSummary

                onCheckedChanged: Configs.weather.enableQuickSummary = checked
            }
        }
        SettingRow {
            description: qsTr("Interval for refreshing weather data, in seconds.")
            label: qsTr("Weather Reload Time (s):")

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.medium
                text: {
                    var secs = Configs.weather.reloadTime / 1000;
                    var mins = Math.round(secs / 60);
                    return qsTr("(%1 min)").arg(mins);
                }
            }
            StyledTextInput {
                Layout.preferredWidth: 200
                text: (Configs.weather.reloadTime / 1000).toString()
                toggleButtonVisible: false

                onTextChanged: {
                    var parsed = parseInt(text);
                    if (!isNaN(parsed) && parsed > 0) {
                        Configs.weather.reloadTime = parsed * 1000;
                    }
                }
            }
        }
    }
}
