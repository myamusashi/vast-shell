pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Button
import qs.Components.Dialog.FileDialog

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Wallpaper Engine")

    SettingsCard {
        Layout.fillWidth: true
        title: qsTr("Pick Wallpaper File")

        SettingRow {
            description: qsTr("Browse and set a new wallpaper image or video.")
            label: qsTr("Select a wallpaper image file:")

            ExtendedFloatingButton {
                icon.name: "image"
                text: qsTr("Browse\u2026")

                onClicked: pickWallpaperDialog.openFileDialog()
            }
            FileDialog {
                id: pickWallpaperDialog

                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.svg", "*.webp", "*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi", "*.m4v"]

                onFileSelected: path => Quickshell.execDetached({
                        command: ["vastctl", "wallpaper", "set", path]
                    })
            }
        }
    }
    SettingsCard {
        Layout.fillWidth: true
        title: qsTr("Wallpaper Picker")
        visible: WallpaperFileModels.wallpaperList.length > 0

        StyledTextInput {
            id: searchField

            Layout.fillWidth: true
            placeHolderText: qsTr("Search wallpapers\u2026")
            toggleButtonVisible: false

            onTextChanged: WallpaperFileModels.searchQuery = text
        }
        PathView {
            id: wallpaperPath

            Layout.fillWidth: true
            Layout.minimumHeight: 160
            cacheItemCount: pathItemCount + 2
            clip: true
            pathItemCount: 5
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5

            delegate: Item {
                id: delegateRoot

                readonly property real itemWidth: wallpaperPath.width / wallpaperPath.pathItemCount
                required property var modelData

                implicitHeight: itemWidth * 0.65
                implicitWidth: itemWidth

                Rectangle {
                    anchors.fill: parent
                    border.color: delegateRoot.modelData === WallpaperFileModels.currentWallpaper ? Colours.m3Colors.m3Primary : "transparent"
                    border.width: delegateRoot.modelData === WallpaperFileModels.currentWallpaper ? 2 : 0
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    radius: Appearance.rounding.small

                    Image {
                        anchors.bottomMargin: fileNameText.implicitHeight + 4
                        anchors.fill: parent
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        source: (width > 0 && height > 0 && !MediaKind.isVideo(delegateRoot.modelData)) ? delegateRoot.modelData : ""
                        sourceSize: Qt.size(150, 150)
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.15)
                        radius: parent.radius
                        visible: delegateRoot.modelData === WallpaperFileModels.currentWallpaper
                    }
                    Rectangle {
                        color: Qt.alpha(Colours.m3Colors.m3Scrim, 0.35)
                        height: fileNameText.implicitHeight + 4

                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        StyledText {
                            id: fileNameText

                            color: Colours.m3Colors.m3OnSurface
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.small
                            horizontalAlignment: Text.AlignHCenter
                            text: delegateRoot.modelData.split('/').pop()

                            anchors {
                                left: parent.left
                                margins: 2
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Quickshell.execDetached({
                            command: ["vastctl", "wallpaper", "set", delegateRoot.modelData]
                        })
                    }
                }
            }
            model: ScriptModel {
                values: WallpaperFileModels.filteredWallpaperList
            }
            path: Path {
                startX: 0
                startY: wallpaperPath.height / 2

                PathLine {
                    x: wallpaperPath.width
                    y: wallpaperPath.height / 2
                }
            }
        }
    }
    SettingsCard {
        Layout.fillWidth: true
        title: qsTr("Image Sourcing")

        GridLayout {
            columns: 2

            SettingRow {
                description: qsTr("Show wallpaper.")
                label: qsTr("Enable Wallpaper:")

                StyledSwitch {
                    checked: Configs.wallpaper.enabledWallpaper

                    onCheckedChanged: Configs.wallpaper.enabledWallpaper = checked
                }
            }
            SettingRow {
                label: qsTr("Wallpaper Live Preview:")

                StyledSwitch {
                    checked: Configs.wallpaper.livePreview

                    onCheckedChanged: Configs.wallpaper.livePreview = checked
                }
            }
        }
        SettingRow {
            description: qsTr("Folder scanned for available wallpapers.")
            label: qsTr("Wallpaper Directory Path:")

            StyledTextInput {
                id: wallpaperDirField

                implicitWidth: 350
                text: Configs.wallpaper.wallpaperDir
                toggleButtonVisible: false

                onTextChanged: Configs.wallpaper.wallpaperDir = text

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

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
            description: qsTr("Number of wallpapers kept in the picker carousel.")
            label: qsTr("Loaded Wallpaper Count:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 1
                showValuePopup: true
                snapEnabled: true
                stepSize: 1
                to: 10
                value: Configs.wallpaper.visibleWallpaper

                onMoved: Configs.wallpaper.visibleWallpaper = value
            }
        }
    }
    SettingsCard {
        Layout.fillWidth: true
        title: qsTr("Transitions & Performance")

        SettingRow {
            description: qsTr("Animation used when switching wallpapers.")
            label: qsTr("Transition Animation Mode:")

            SplitButton {
                readonly property int selectedIndex: model.findIndex(entry => entry.display === Configs.wallpaper.transition)

                currentIndex: selectedIndex
                icon.name: "transition_chop"
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
                    },
                    {
                        display: "hexTile"
                    }
                ]
                text: model[selectedIndex]?.display ?? Configs.wallpaper.transition
                textRole: "display"

                onMenuItemActivated: index => Configs.wallpaper.transition = model[index].display
            }
        }
        SettingRow {
            description: qsTr("Reduce transition quality to improve performance on low-end hardware.")
            label: qsTr("Transition Low Performance Priority:")

            StyledSwitch {
                checked: Configs.wallpaper.transitionLowPerfMode

                onCheckedChanged: Configs.wallpaper.transitionLowPerfMode = checked
            }
        }
        SettingRow {
            description: qsTr("Duration of the wallpaper switch animation in milliseconds.")
            label: qsTr("Transition Duration (ms):")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 100
                stepSize: 50
                to: 2000
                value: Configs.wallpaper.transitionDuration

                onMoved: Configs.wallpaper.transitionDuration = value
            }
        }
    }
}
