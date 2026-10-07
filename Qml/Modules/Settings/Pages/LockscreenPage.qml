pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Feedback
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../Components"
import "./Lockscreen"

SettingsPageBase {
    id: root

    readonly property bool   currentIsVideo: MediaKind.isVideo(Paths.currentWallpaper)
    readonly property string sourcePreview: currentIsVideo ? "file://" + MediaKind.videoThumbnailPathFor(Paths.currentWallpaper) + "?v=" + Wallpaper.thumbnailVersion : MediaKind.staticPathFor(Paths.currentWallpaper)

    pageTitle: qsTr("Lockscreen")

    SettingsCard {
        title: qsTr("Preview")

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.small
            text: qsTr("Depth wallpaper supports static images only. A video wallpaper is active, so the depth effect is paused.")
            visible: root.currentIsVideo
            wrapMode: Text.Wrap
        }

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

            Rectangle {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3SurfaceContainerHigh
                radius: Appearance.rounding.small

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: DepthWallpaperController.state === "done" ? "file://" + DepthWallpaperController.fgPath : ""
                    visible: source !== ""
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.7)
                    radius: parent.radius
                    visible: DepthWallpaperController.state === "processing"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small

                        LoadingIndicator {
                            Layout.alignment: Qt.AlignCenter
                            implicitHeight: 24
                            implicitWidth: 24
                            status: DepthWallpaperController.state === "processing"
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignCenter
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.medium
                            text: qsTr("Loading")
                        }
                    }
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        switch (DepthWallpaperController.state) {
                        case "processing":
                            return qsTr("Processing");
                        case "done":
                            return qsTr("Foreground");
                        case "error":
                            return qsTr("Error");
                        default:
                            return qsTr("Not generated");
                        }
                    }

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

    DepthWallpaperSection {
        Layout.fillWidth: true
    }
}
