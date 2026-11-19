pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services

Item {
    id: root

    property var trackArtColors: TrackArt.colors

    Layout.fillWidth: true
    implicitHeight: 150
    visible: Players.active !== null

    ClippingRectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Appearance.rounding.small
        visible: !!Players.active?.trackArtUrl

        Image {
            id: trackArt

            anchors.fill: parent
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
            sourceSize: Qt.size(400, 200)

            Rectangle {
                anchors.fill: parent
                color: Colours.m3Colors.m3Background
                opacity: 0.5
                z: 2
            }
        }
    }

    Loader {
        id: contentLoader

        active: Players.active !== null
        anchors.fill: parent
        asynchronous: true
        sourceComponent: ContentMediaPlayer {
            trackArtColors: root.trackArtColors
            width: contentLoader.width
        }
    }
}
