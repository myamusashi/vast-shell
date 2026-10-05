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

    Layout.fillWidth: true
    color: "transparent"
    implicitHeight: 150
    radius: Appearance.rounding.small
    visible: Players.active !== null

    Item {
        anchors.fill: parent

        Image {
            id: trackArt

            anchors.fill: parent
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
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

            active: GlobalStates.isQuickSettingsOpen
            anchors.fill: parent
            asynchronous: true

            sourceComponent: ContentMediaPlayer {
                trackArtColors: root.trackArtColors
                width: contentLoader.width
            }
        }
    }
}
