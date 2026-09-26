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

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: Appearance.spacing.large

        SettingsCard {
            title: qsTr("Depth Wallpaper")

            SettingRow {
                label: qsTr("Video wallpaper active")
                description: qsTr("Depth wallpaper is static-image only. Switch to a static wallpaper to enable it.")
                visible: MediaKind.isVideo(Paths.currentWallpaper)
            }

            SettingRow {
                label: qsTr("Enable Depth Wallpaper")
                description: qsTr("Enable depth effect (Apple like).")

                StyledSwitch {
                    checked: Configs.wallpaper.depthWallpaperEnabled
                    enabled: !MediaKind.isVideo(Paths.currentWallpaper)
                    onCheckedChanged: DepthWallpaperController.onToggle(checked)
                }
            }

            SettingRow {
                label: qsTr("Auto-process on wallpaper change:")
                description: qsTr("Automatically regenerate the depth map whenever the wallpaper changes.")

                StyledSwitch {
                    checked: Configs.wallpaper.autoProcessedDepthWallpaper
                    onCheckedChanged: Configs.wallpaper.autoProcessedDepthWallpaper = checked
                }
            }

            ExtendedFloatingButton {
                text: qsTr("Re-generate")
                icon.name: "refresh"
                implicitHeight: 36
                visible: Configs.wallpaper.depthWallpaperEnabled && DepthWallpaperController.state !== "processing" && !MediaKind.isVideo(Paths.currentWallpaper)
                enabled: DepthWallpaperController.state !== "processing" && !MediaKind.isVideo(Paths.currentWallpaper)
                onClicked: DepthWallpaperController.runRembg()
            }

            StyledText {
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
                font.pixelSize: Appearance.fonts.size.medium
                color: DepthWallpaperController.state === "error" ? Colours.m3Colors.m3Error : DepthWallpaperController.state === "done" ? Colours.m3Colors.m3Green : Colours.m3Colors.m3OnSurfaceVariant
                visible: text !== ""
            }

            StyledText {
                text: qsTr("Unavailable while a video wallpaper is active.")
                font.pixelSize: Appearance.fonts.size.small
                color: Colours.m3Colors.m3OnSurfaceVariant
                visible: MediaKind.isVideo(Paths.currentWallpaper)
            }
        }
    }
}
