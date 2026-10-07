import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Button

import "../../Components"

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        spacing: Appearance.spacing.large

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        SettingsCard {
            title: qsTr("Depth Wallpaper")

            SettingRow {
                description: qsTr("Depth wallpaper is static-image only. Switch to a static wallpaper to enable it.")
                label: qsTr("Video wallpaper active")
                visible: MediaKind.isVideo(Paths.currentWallpaper)
            }

            SettingRow {
                description: qsTr("Enable depth effect (Apple like).")
                label: qsTr("Enable Depth Wallpaper")

                StyledSwitch {
                    checked: Configs.wallpaper.depthWallpaperEnabled
                    enabled: !MediaKind.isVideo(Paths.currentWallpaper)
                    onCheckedChanged: DepthWallpaperController.onToggle(checked)
                }
            }

            SettingRow {
                description: qsTr("Automatically regenerate the depth map whenever the wallpaper changes.")
                label: qsTr("Auto-process on wallpaper change:")

                StyledSwitch {
                    checked: Configs.wallpaper.autoProcessedDepthWallpaper
                    onCheckedChanged: Configs.wallpaper.autoProcessedDepthWallpaper = checked
                }
            }

            ExtendedFloatingButton {
                enabled: DepthWallpaperController.state !== "processing" && !MediaKind.isVideo(Paths.currentWallpaper)
                icon.name: "refresh"
                implicitHeight: 36
                text: qsTr("Re-generate")
                visible: Configs.wallpaper.depthWallpaperEnabled && DepthWallpaperController.state !== "processing" && !MediaKind.isVideo(Paths.currentWallpaper)
                onClicked: DepthWallpaperController.runRembg()
            }

            StyledText {
                color: DepthWallpaperController.state === "error" ? Colours.m3Colors.m3Error : DepthWallpaperController.state === "done" ? Colours.m3Colors.m3Green : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.medium
                text: {
                    switch (DepthWallpaperController.state) {
                    case "processing":
                        return qsTr("Generating depth map\u2026");
                    case "done":
                        return qsTr("Depth wallpaper ready");
                    case "error":
                        return DepthWallpaperController.errorMessage;
                    default:
                        return "";
                    }
                }
                visible: text !== ""
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("Unavailable while a video wallpaper is active.")
                visible: MediaKind.isVideo(Paths.currentWallpaper)
            }
        }
    }
}
