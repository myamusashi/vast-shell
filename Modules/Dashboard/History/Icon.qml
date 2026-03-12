pragma ComponentBehavior: Bound

import QtQuick
import Vast

import qs.Components.Base
import qs.Components.Feedback
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Loader {
    id: root

    required property var modelData
    property string thumbnailPath: ""
    property bool showLoading: true

    active: GlobalStates.isDashboardOpen
    width: 70
    height: 70

    Component.onCompleted: {
        const ext = getFileExtension(root.modelData.path);
        const videoFormats = ["mkv", "mp4", "webm", "avi"];

        if (videoFormats.includes(ext))
            ScreenRecorder.createThumbnail(root.modelData.path, Paths.cacheDir + "/video-thumbnails");
        else
            thumbnailPath = "file://" + root.modelData.path;
    }

    function getFileExtension(filepath) {
        const filename = filepath.split('/').pop();
        const lastDot = filename.lastIndexOf('.');
        if (lastDot === -1 || lastDot === 0)
            return '';
        return filename.substring(lastDot + 1).toLowerCase();
    }

    Connections {
        target: ScreenRecorder

        function onThumbnailReady(videoPath, thumbnailPath) {
            if (videoPath !== root.modelData.path)
                return;
            delayTimer.thumbnailData = thumbnailPath !== "" ? "file://" + thumbnailPath : "";
            delayTimer.start();
        }
    }

    sourceComponent: StyledRect {
        implicitWidth: 70
        implicitHeight: 70
        radius: Appearance.rounding.full
        color: Colours.m3Colors.m3PrimaryContainer

        Image {
            id: image

            anchors.centerIn: parent
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            width: 40
            height: 40
            sourceSize: Qt.size(40, 40)
            source: root.thumbnailPath

            Rectangle {
                anchors.fill: parent
                color: Colours.m3Colors.m3SurfaceVariant
                visible: image.status === Image.Error || image.status === Image.Null
                radius: parent.width / 2

                StyledText {
                    anchors.centerIn: parent
                    text: {
                        const ext = root.getFileExtension(root.modelData.path);
                        const videoFormats = ["mkv", "mp4", "webm", "avi"];
                        return videoFormats.includes(ext) ? "📹" : "🖼️";
                    }
                    font.pixelSize: Appearance.fonts.size.large
                }
            }

            LoadingIndicator {
                implicitWidth: 30
                implicitHeight: 30
                status: {
                    if (root.getFileExtension(root.modelData.path) === "mkv" || root.getFileExtension(root.modelData.path) === "mp4")
                        return root.showLoading || image.status == Image.Loading;
                    else
                        return image.status == Image.Loading;
                }
            }
        }
    }

    Timer {
        id: delayTimer

        property string thumbnailData: ""

        interval: 500
        repeat: false
        onTriggered: {
            root.thumbnailPath = thumbnailData;
            root.showLoading = false;
        }
    }
}
