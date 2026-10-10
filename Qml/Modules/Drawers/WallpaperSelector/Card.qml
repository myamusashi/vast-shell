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

    required property real carouselHeight
    required property var  controller
    required property int  index
    required property bool isCurrent
    required property var  modelData
    required property var  thumbnailAvailability

    signal                 activateRequested(var modelData)
    signal                 selectRequested(int index)

    // Portion of this slot currently inside the viewport. Cards squash against
    // the edge while scrolling instead of being cropped by the view clip.
    readonly property real viewportLeft: ListView.view.contentX
    readonly property real viewportRight: viewportLeft + ListView.view.width
    readonly property real visibleWidth: Math.max(0, Math.min(x + width, viewportRight) - Math.max(x, viewportLeft))

    z: isCurrent ? 100 : 1
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

        height: root.isCurrent ? root.carouselHeight : root.carouselHeight * 0.82
        width: root.visibleWidth
        x: Math.max(root.x, root.viewportLeft) - root.x
        y: (root.carouselHeight - height) / 2
        color: "transparent"
        opacity: root.isCurrent ? 1.0 : 0.92
        radius: root.isCurrent ? Appearance.rounding.large : Appearance.rounding.normal
        Behavior on height {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Elevation {
            anchors.fill: parent
            level: root.isCurrent ? 3 : 0
            z: -1
        }

        Image {
            anchors.fill: parent
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            source: MediaKind.isVideo(root.modelData) ? "" : "file://" + root.modelData
            sourceSize: Qt.size(200, 200)
        }

        Image {
            id: videoThumbnailCache

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: root.thumbnailAvailability[root.modelData] ? "file://" + MediaKind.videoThumbnailPathFor(root.modelData) + "?v=" + root.controller.thumbnailVersion : ""
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
            color: root.isCurrent ? "transparent" : Qt.rgba(0, 0, 0, 0.22)
            radius: card.radius
            Behavior on color {
                CAnim {}
            }
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
