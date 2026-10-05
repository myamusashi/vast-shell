import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Button
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Media Player")

    SettingsCard {
        title: qsTr("Player Preferences")

        SettingRow {
            description: qsTr("Fetch and display synchronized lyrics when available.")
            label: qsTr("Enable lyrics in media player:")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: Configs.mediaPlayer.showLyrics

                onToggled: Configs.mediaPlayer.showLyrics = checked
            }
        }
        SettingRow {
            description: qsTr("Tint the player with colors extracted from the album cover.")
            label: qsTr("Enable dynamic colors from cover art:")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: Configs.mediaPlayer.dynamicColorsCover

                onToggled: Configs.mediaPlayer.dynamicColorsCover = checked
            }
        }
        SettingRow {
            description: qsTr("Visual style for the playback progress slider.")
            label: qsTr("Slider type:")

            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.display === Configs.mediaPlayer.sliderType)

                currentIndex: selectedIndex
                icon.name: "sliders"
                model: [
                    {
                        display: "Wavy"
                    },
                    {
                        display: "WaveForm"
                    }
                ]
                text: model[selectedIndex]?.display ?? Configs.mediaPlayer.sliderType
                textRole: "display"

                onMenuItemActivated: index => Configs.mediaPlayer.sliderType = model[index].display
            }
        }
    }
}
