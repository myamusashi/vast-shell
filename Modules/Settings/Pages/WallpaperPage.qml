import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Dialog.FileDialog

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Wallpaper Engine")

    SettingsCard {
        title: qsTr("Image Sourcing")

        SettingRow {
            label: qsTr("Enable Wallpaper:")

            StyledSwitch {
                checked: Configs.wallpaper.enabledWallpaper
                onCheckedChanged: Configs.wallpaper.enabledWallpaper = checked
            }
        }

        SettingRow {
            label: qsTr("Wallpaper Directory Path:")

            StyledTextInput {
                id: wallpaperDirField

                text: Configs.wallpaper.wallpaperDir
                onTextChanged: Configs.wallpaper.wallpaperDir = text
                implicitWidth: 350
                toggleButtonVisible: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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

        SettingRow {
            label: qsTr("Loaded Wallpaper Count:")

            StyledSlide {
                from: 1
                to: 10
                stepSize: 1
                snapEnabled: true
                showValuePopup: true
                value: Configs.wallpaper.visibleWallpaper
                onMoved: Configs.wallpaper.visibleWallpaper = value
                Layout.preferredWidth: 200
            }
        }
    }

    SettingsCard {
        title: qsTr("Transitions & Performance")

        SettingRow {
            label: qsTr("Transition Animation Mode:")

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

        SettingRow {
            label: qsTr("Transition Low Performance Priority:")

            StyledSwitch {
                checked: Configs.wallpaper.transitionLowPerfMode
                onCheckedChanged: Configs.wallpaper.transitionLowPerfMode = checked
            }
        }

        SettingRow {
            label: qsTr("Transition Duration (ms):")

            StyledSlide {
                from: 100
                to: 2000
                stepSize: 50
                value: Configs.wallpaper.transitionDuration
                onMoved: Configs.wallpaper.transitionDuration = value
                Layout.preferredWidth: 200
            }
        }
    }

    DepthWallpaperSection {
        Layout.fillWidth: true
    }
}
