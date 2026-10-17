pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services as Svc
import qs.Components.Base
import qs.Components.Button
import qs.Components.Dialog.FileDialog
import qs.Modules.Drawers.WallpaperSelector

import "../Components"

SettingsPageBase {
    id: root

    readonly property string currentWallpaperPreview: {
        const path = Paths.currentWallpaper;
        if (path === "")
            return "";
        if (!MediaKind.isVideo(path))
            return "file://" + MediaKind.staticPathFor(path);
        if (Svc.Wallpaper.thumbnailAvailability[path] !== true)
            return "";
        return `file://${MediaKind.videoThumbnailPathFor(path)}?v=${Svc.Wallpaper.thumbnailVersion}`;
    }

    pageTitle: qsTr("Wallpaper Engine")

    SettingsCard {
        Layout.fillWidth: true
        title: qsTr("Wallpaper Picker")

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            color: Colours.m3Colors.m3SurfaceContainerHigh
            radius: Appearance.rounding.normal

            Image {
                id: currentPreview

                anchors.fill: parent
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                source: root.currentWallpaperPreview
                sourceSize: Qt.size(720, 150)
                visible: status === Image.Ready

                Rectangle {
                    anchors.fill: parent
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    visible: !currentPreview.visible

                    Icon {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        icon: "image"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            spacing: Appearance.spacing.normal

            // qmlformat off
            readonly property list<color> palettePreviewColors: [
                Colours.m3Colors.m3Primary,
                Colours.m3Colors.m3PrimaryContainer,
                Colours.m3Colors.m3Secondary,
                Colours.m3Colors.m3SecondaryContainer,
                Colours.m3Colors.m3Tertiary,
                Colours.m3Colors.m3TertiaryContainer,
            ]
            // qmlformat on

            Repeater {
                model: parent.palettePreviewColors
                delegate: Rectangle {
                    required property color modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    color: modelData
                    radius: Appearance.rounding.small
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            Icon {
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
                icon: "search"
            }

            StyledTextInput {
                Layout.fillWidth: true
                placeHolderText: qsTr("Search wallpapers…")
                text: Svc.WallpaperFileModels.searchQuery
                toggleButtonVisible: false
                onTextChanged: {
                    Svc.WallpaperFileModels.searchQuery = text;
                    wallpaperCarousel.currentIndex      = 0;
                }
            }
        }

        FileDialog {
            id: pickWallpaperDialog

            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.svg", "*.webp", "*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi", "*.m4v"]
            onFileSelected: path => Quickshell.execDetached({
                    command: ["vastctl", "wallpaper", "set", path]
                })
        }

        ConnectedButtonGroup {
            Layout.alignment: Qt.AlignHCenter
            currentIndex: Svc.Wallpaper.wallpaperType
            model: [qsTr("Static"), qsTr("Video")]
            onClicked: index => {
                Svc.Wallpaper.wallpaperType = index;
                Qt.callLater(() => wallpaperCarousel.selectCurrentWallpaper());
            }
        }

        Carousel {
            id: wallpaperCarousel

            Layout.fillWidth: true
            Layout.minimumHeight: 180
            Layout.preferredHeight: 200
            applyOnClick: true
            closeDrawerOnEscape: false
            controller: Svc.Wallpaper
            thumbnailAvailability: Svc.Wallpaper.thumbnailAvailability
            visibleWallpapers: Svc.Wallpaper.visibleWallpapers
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.small
            text: wallpaperCarousel.count > 0 ? (wallpaperCarousel.currentIndex + 1) + " / " + wallpaperCarousel.count : "0 / 0"
            visible: wallpaperCarousel.count > 0
        }

        StyledText {
            color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.5)
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.small
            text: qsTr("Browse and set a new wallpaper image or video.")
        }

        ExtendedFloatingButton {
            icon.name: "image"
            text: qsTr("Browse…")
            onClicked: pickWallpaperDialog.openFileDialog()
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
