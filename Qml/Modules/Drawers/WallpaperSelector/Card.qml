pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Vast.ImageCache

import qs.Components.Base
import qs.Components.Effects
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
    required property real unitWidth

    signal                 activateRequested(var modelData)
    signal                 selectRequested(int index)

    implicitHeight: carouselHeight
    implicitWidth: isCurrent ? unitWidth * 2 : unitWidth
    opacity: isCurrent ? 1.0 : 0.92
    z: isCurrent ? 100 : 1
    Behavior on implicitWidth {
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
    onIsCurrentChanged: {
        if (!isCurrent)
            return;
        if (MediaKind.isVideo(modelData))
            controller.ensureThumbnail(modelData);
        else
            ImageCache.preload(modelData, Qt.size(Screen.width, Screen.height));
    }

    ClippingRectangle {
        id: cardRect

        anchors.centerIn: parent
        color: "transparent"
        implicitHeight: parent.height
        implicitWidth: parent.width - (root.isCurrent ? Math.max(20, root.unitWidth * 0.3) : Math.max(12, root.unitWidth * 0.2))
        radius: root.isCurrent ? Appearance.rounding.large : 20
        Behavior on implicitHeight {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on implicitWidth {
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

        Image {
            anchors.fill: parent
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            source: MediaKind.isVideo(root.modelData) ? "" : "file://" + root.modelData
            sourceSize: Qt.size(200, 200)

            Elevation {
                anchors.fill: parent
                level: 3
                z: -1
            }
        }

        Image {
            id: videoThumbnailCache

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: root.thumbnailAvailability[root.modelData] ? "file://" + MediaKind.videoThumbnailPathFor(root.modelData) + "?v=" + root.controller.thumbnailVersion : ""
            visible: status === Image.Ready
            onStatusChanged: {
                if (status === Image.Error && MediaKind.isVideo(root.modelData) && root.thumbnailAvailability[root.modelData])
                    root.controller.markThumbnail(root.modelData, false);
            }
        }

        Rectangle {
            id: dimOverlay

            property color target: Qt.rgba(0, 0, 0, root.isCurrent ? 0.0 : 0.22)

            anchors.fill: parent
            radius: cardRect.radius

            BlendColor {
                host: dimOverlay
                target: dimOverlay.target
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
