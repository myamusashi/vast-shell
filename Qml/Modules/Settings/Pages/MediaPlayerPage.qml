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
            description: qsTr("Shift lyric timing in milliseconds (positive shows lyrics earlier, negative delays them).")
            label: qsTr("Lyrics timing offset (%1 ms):").arg(Configs.mediaPlayer.lyricsOffsetMs)

            StyledSlide {
                Layout.preferredWidth: 200
                from: -1000
                popupValueFormat: v => `${Math.round(v)} ms`
                stepSize: 10
                to: 1000
                value: Configs.mediaPlayer.lyricsOffsetMs
                onMoved: Configs.mediaPlayer.lyricsOffsetMs = Math.round(value)
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
            description: qsTr("Follow the player that is currently playing instead of staying on the first one.")
            label: qsTr("Auto-switch to the active player:")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: Configs.mediaPlayer.autoSwitchActivePlayer
                onToggled: Configs.mediaPlayer.autoSwitchActivePlayer = checked
            }
        }

        SettingRow {
            description: qsTr("Visual style for the playback progress slider.")
            label: qsTr("Slider type:")

            ConnectedButtonGroup {
                readonly property int selectedIndex: model.findIndex(entry => entry === Configs.mediaPlayer.sliderType)

                currentIndex: selectedIndex
                model: ["Wavy", "WaveForm"]
                onClicked: index => Configs.mediaPlayer.sliderType = model[index]
            }
        }
    }
}
