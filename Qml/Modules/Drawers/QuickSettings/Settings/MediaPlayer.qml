pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Services

ClippingWrapperRectangle {
    id: root

    property var trackArtColors: TrackArt.colors

    implicitHeight: 150
    Layout.fillWidth: true
    visible: Players.active !== null
    color: "transparent"
    radius: Appearance.rounding.small

    Item {
        anchors.fill: parent

        Image {
            id: trackArt

            anchors.fill: parent
            source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            visible: !!Players.active?.trackArtUrl

            Rectangle {
                anchors.fill: parent
                color: Colours.m3Colors.m3Background
                opacity: 0.5
                z: 2
            }
        }

        Loader {
            id: contentLoader

            anchors.fill: parent
            active: GlobalStates.isQuickSettingsOpen
            asynchronous: true
            sourceComponent: ContentMediaPlayer {
                width: contentLoader.width
                trackArtColors: root.trackArtColors
            }
        }
    }
}
