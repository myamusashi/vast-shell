pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Core.States
import qs.Services

ClippingWrapperRectangle {
    id: root

    property var trackArtColors: TrackArt.colors

    Item {
        anchors.fill: parent

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: Colours.m3Colors.m3Background
                opacity: 0.5
                z: 2
            }

            Image {
                id: trackArt

                anchors.fill: parent
                source: Players.active.trackArtUrl
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: !!Players.active?.trackArtUrl
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
