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
            Layout.bottomMargin: Appearance.margin.normal
            text: qsTr("Media Player")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
        }

        SettingsCard {
            title: qsTr("Player Preferences")

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Enable lyrics in media player:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSwitch {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    checked: Configs.mediaPlayer.showLyrics
                    onToggled: Configs.mediaPlayer.showLyrics = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Enable dynamic colors from cover art:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSwitch {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    checked: Configs.mediaPlayer.dynamicColorsCover
                    onToggled: Configs.mediaPlayer.dynamicColorsCover = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Slider type:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledComboBox {
                    id: waveTypeCombo

                    Layout.preferredWidth: 250
                    model: [
                        {
                            display: "Wavy"
                        },
                        {
                            display: "WaveForm"
                        }
                    ]
                    currentIndex: -1
                    placeholderText: Configs.mediaPlayer.sliderType
                    isItemActive: (md, _) => md.display === Configs.mediaPlayer.sliderType
                    onActivated: index => Configs.mediaPlayer.sliderType = model[index].display
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
