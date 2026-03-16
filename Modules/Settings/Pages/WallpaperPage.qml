import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Dialog.FileDialog

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
            text: qsTr("Wallpaper Engine")
            font {
                pixelSize: Appearance.fonts.size.extraLarge
                bold: true
            }
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("Image Sourcing")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Enable Wallpaper:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
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
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledTextInput {
                    id: wallpaperDirField

                    text: Configs.wallpaper.wallpaperDir
                    onTextChanged: Configs.wallpaper.wallpaperDir = text
                    implicitWidth: 350

                    MArea {
                        onClicked: {
                            wallpaperDirField.forceActiveFocus();
                            fileDialog.openFileDialog();
                        }
                    }
                }

                FileDialog {
                    id: fileDialog

                    foldersOnly: true
                    selectFolder: true
                    showHidden: true
                    onFileSelected: path => Configs.wallpaper.wallpaperDir = path
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Loaded Wallpaper Count:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSlide {
                    from: 1
                    to: 10
                    stepSize: 1
                    snapEnabled: true
                    showValuePopup: true
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
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledComboBox {
                    model: [
                        {
                            display: "none"
                        },
                        {
                            display: "random"
                        },
                        {
                            display: "fade"
                        },
                        {
                            display: "wipedown"
                        },
                        {
                            display: "circle"
                        },
                        {
                            display: "dissolve"
                        },
                        {
                            display: "splitH"
                        },
                        {
                            display: "slideup"
                        },
                        {
                            display: "pixelate"
                        },
                        {
                            display: "diagonal"
                        },
                        {
                            display: "box"
                        },
                        {
                            display: "roll"
                        }
                    ]
                    Layout.preferredWidth: 200
                    currentIndex: -1
                    placeholderText: Configs.wallpaper.transition
                    isItemActive: (md, _) => md.display === Configs.wallpaper.transition
                    onActivated: index => Configs.wallpaper.transition = model[index].display
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Transition Low Performance Priority:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
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
                    font.pixelSize: Appearance.fonts.size.large
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
