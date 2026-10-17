pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import QtMultimedia
import Vast.ImageCache

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils

Item {
    id: root

    required property real closeness
    required property var  controller
    required property int  index
    required property bool isCurrent
    required property var  modelData
    required property var  thumbnailAvailability
    required property real viewportWidth

    readonly property real foldFraction: width > 0 ? visibleWidth / width : 0
    readonly property real visibleWidth: Math.max(0, Math.min(x + width, viewportWidth) - Math.max(x, 0))

    signal                 activateRequested(var modelData)
    signal                 selectRequested(int index)

    z: closeness
    onIsCurrentChanged: {
        if (!isCurrent)
            return;
        if (MediaKind.isVideo(modelData))
            controller.ensureThumbnail(modelData);
        else
            ImageCache.preload(modelData, Qt.size(Screen.width, Screen.height));
    }

    ClippingRectangle {
        id: card

        anchors.fill: parent
        color: "transparent"
        opacity: 0.85 + 0.15 * root.closeness
        radius: Appearance.rounding.normal
        visible: root.foldFraction > 0.01
        transform: Scale {
            origin.x: root.x < 0 ? root.width : 0
            xScale: root.foldFraction
        }

        Elevation {
            anchors.fill: parent
            level: root.closeness > 0.5 ? 3 : 0
            z: -1
        }

        Image {
            anchors.fill: parent
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            source: root.visible && !MediaKind.isVideo(root.modelData) ? "file://" + root.modelData : ""
            sourceSize: Qt.size(200, 200)
        }

        Image {
            id: videoThumbnailCache

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: root.visible && root.thumbnailAvailability[root.modelData] ? "file://" + MediaKind.videoThumbnailPathFor(root.modelData) + "?v=" + root.controller.thumbnailVersion : ""
            visible: status === Image.Ready && !videoPreview.active
            onStatusChanged: {
                if (status === Image.Error && MediaKind.isVideo(root.modelData) && root.thumbnailAvailability[root.modelData])
                    root.controller.markThumbnail(root.modelData, false);
            }
        }

        Loader {
            id: videoPreview

            active: root.isCurrent && MediaKind.isVideo(root.modelData)
            anchors.fill: parent
            asynchronous: false
            sourceComponent: Component {

                Item {

                    MediaPlayer {
                        id: cardVideoPlayer

                        loops: MediaPlayer.Infinite
                        source: Qt.resolvedUrl(root.modelData)
                        videoOutput: cardVideoOutput
                        onErrorOccurred: (error, errorString) => {
                            console.warn("[WallpaperSelector] Card video error:", errorString);
                            videoPreview.active = false;
                        }
                        onMediaStatusChanged: {
                            if (mediaStatus === MediaPlayer.LoadedMedia)
                                play();
                        }
                    }

                    VideoOutput {
                        id: cardVideoOutput

                        anchors.fill: parent
                        endOfStreamPolicy: VideoOutput.KeepLastFrame
                        fillMode: VideoOutput.PreserveAspectCrop
                    }
                }
            }
        }

        Rectangle {
            id: dimOverlay

            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.22 * (1 - root.closeness) + 0.3 * (1 - root.foldFraction))
            radius: card.radius
        }

        MArea {
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!root.isCurrent)
                    root.selectRequested(root.index);
                else
                    root.activateRequested(root.modelData);
            }
        }
    }
}
