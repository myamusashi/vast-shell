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
    pageTitle: qsTr("Lockscreen")

    readonly property bool currentIsVideo: MediaKind.isVideo(Paths.currentWallpaper)
    readonly property string sourcePreview: currentIsVideo ? "file://" + MediaKind.videoThumbnailPathFor(Paths.currentWallpaper) + "?v=" + Wallpaper.thumbnailVersion : MediaKind.staticPathFor(Paths.currentWallpaper)
    SettingsCard {
        title: qsTr("Preview")

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Depth wallpaper supports static images only. A video wallpaper is active, so the depth effect is paused.")
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3Error
            wrapMode: Text.Wrap
            visible: root.currentIsVideo
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: Appearance.rounding.small
                color: Colours.m3Colors.m3SurfaceContainerHigh

                Image {
                    anchors.fill: parent
                    source: root.sourcePreview
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                StyledText {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        margins: Appearance.margin.small
                    }
                    text: qsTr("Source")
                    font.pixelSize: Appearance.fonts.size.small
                    color: Colours.m3Colors.m3OnSurface
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.rounding.small
                color: Colours.m3Colors.m3SurfaceContainerHigh

                Image {
                    anchors.fill: parent
                    source: DepthWallpaperController.state === "done" ? "file://" + DepthWallpaperController.fgPath : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: source !== ""
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.7)
                    visible: DepthWallpaperController.state === "processing"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small

                        LoadingIndicator {
                            Layout.alignment: Qt.AlignCenter
                            implicitWidth: 24
                            implicitHeight: 24
                            status: DepthWallpaperController.state === "processing"
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignCenter
                            text: qsTr("Loading")
                            font.pixelSize: Appearance.fonts.size.medium
                            color: Colours.m3Colors.m3Primary
                        }
                    }
                }

                StyledText {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        margins: Appearance.margin.small
                    }
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
                    font.pixelSize: Appearance.fonts.size.small
                    color: Colours.m3Colors.m3OnSurface
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    DepthWallpaperSection {
        Layout.fillWidth: true
    }
}
