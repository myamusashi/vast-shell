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
            label: qsTr("Latitude:")

            StyledTextInput {
                text: Configs.weather.latitude
                onTextChanged: Configs.weather.latitude = text
                Layout.preferredWidth: 250
                placeHolderText: "e.g., -6.200000"
                toggleButtonVisible: false
            }
        }

        SettingRow {
            label: qsTr("Longitude:")

            StyledTextInput {
                text: Configs.weather.longitude
                onTextChanged: Configs.weather.longitude = text
                Layout.preferredWidth: 250
                placeHolderText: "e.g., 106.816666"
                toggleButtonVisible: false
            }
        }
    }

    SettingsCard {
        title: qsTr("Sync & Overview")

        SettingRow {
            label: qsTr("Enable Quick Summary Widget:")

            StyledSwitch {
                checked: Configs.weather.enableQuickSummary
                onCheckedChanged: Configs.weather.enableQuickSummary = checked
            }
        }

        SettingRow {
            label: qsTr("Weather Reload Time (ms):")

            StyledTextInput {
                text: Configs.weather.reloadTime.toString()
                onTextChanged: {
                    var parsed = parseInt(text);
                    if (!isNaN(parsed) && parsed > 0) {
                        Configs.weather.reloadTime = parsed;
                    }
                }
                Layout.preferredWidth: 200
                toggleButtonVisible: false
            }
        }
    }
}
