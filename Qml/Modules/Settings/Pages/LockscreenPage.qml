pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    readonly property bool   currentIsVideo: MediaKind.isVideo(Paths.currentWallpaper)
    readonly property string sourcePreview: currentIsVideo ? "file://" + MediaKind.videoThumbnailPathFor(Paths.currentWallpaper) + "?v=" + Wallpaper.thumbnailVersion : MediaKind.staticPathFor(Paths.currentWallpaper)

    pageTitle: qsTr("Lockscreen")

    SettingsCard {
        title: qsTr("Preview")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: Colours.m3Colors.m3SurfaceContainerHigh
                radius: Appearance.rounding.small

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: root.sourcePreview
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Source")

                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        margins: Appearance.margin.small
                        right: parent.right
                    }
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Window Privacy")

        SettingRow {
            description: qsTr("Render windows on each monitor's active workspace blurred behind the lock screen.")
            label: qsTr("Blur windows on lock:")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: Configs.lockscreen.blurWindowsEnabled
                onToggled: Configs.lockscreen.blurWindowsEnabled = checked
            }
        }

        SettingRow {
            label: qsTr("Blur radius:")

            StyledSlide {
                Layout.preferredWidth: 200
                enabled: Configs.lockscreen.blurWindowsEnabled
                from: 8
                stepSize: 1
                to: 128
                value: Configs.lockscreen.blurRadius
                onMoved: Configs.lockscreen.blurRadius = value
            }
        }
    }
}
