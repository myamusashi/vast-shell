import QtQuick
import QtQuick.Layouts
import qs.Configs
import qs.Components
import qs.Services
import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors {
            fill: parent
            margins: Configs.appearance.margin.large
        }
        spacing: Configs.appearance.spacing.large

        StyledText {
            text: qsTr("Wallpaper Engine")
            font {
                pixelSize: Configs.appearance.fonts.size.extraLarge
                bold: true
            }
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Configs.appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("Image Sourcing")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Enable Wallpaper:")
                    Layout.fillWidth: true
                    font.pixelSize: Configs.appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSwitch {
                    checked: Configs.wallpaper.enabledWallpaper
                    onCheckedChanged: Configs.wallpaper.enabledWallpaper = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Wallpaper Directory Path:")
                    Layout.fillWidth: true
                    font.pixelSize: Configs.appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledTextField {
                    text: Configs.wallpaper.wallpaperDir
                    onTextChanged: Configs.wallpaper.wallpaperDir = text
                    Layout.preferredWidth: 350
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Loaded Wallpaper Count:")
                    Layout.fillWidth: true
                    font.pixelSize: Configs.appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSlide {
                    from: 1
                    to: 10
                    stepSize: 1
                    value: Configs.wallpaper.visibleWallpaper
                    onValueChanged: Configs.wallpaper.visibleWallpaper = value
                    Layout.preferredWidth: 200
                }
            }
        }

        SettingsCard {
            title: qsTr("Transitions & Performance")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Transition Animation Mode:")
                    Layout.fillWidth: true
                    font.pixelSize: Configs.appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledTextField {
                    text: Configs.wallpaper.transition
                    onTextChanged: Configs.wallpaper.transition = text
                    Layout.preferredWidth: 200
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Transition Low Performance Priority:")
                    Layout.fillWidth: true
                    font.pixelSize: Configs.appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSwitch {
                    checked: Configs.wallpaper.transitionLowPerfMode
                    onCheckedChanged: Configs.wallpaper.transitionLowPerfMode = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Transition Duration (ms):")
                    Layout.fillWidth: true
                    font.pixelSize: Configs.appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSlide {
                    from: 100
                    to: 2000
                    stepSize: 50
                    value: Configs.wallpaper.transitionDuration
                    onValueChanged: Configs.wallpaper.transitionDuration = value
                    Layout.preferredWidth: 200
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
