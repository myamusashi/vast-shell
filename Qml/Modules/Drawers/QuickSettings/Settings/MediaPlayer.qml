pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Widgets

ColumnLayout {
    id: root

    readonly property color accentColor: Configs.mediaPlayer.dynamicColorsCover && trackArtColors.primary ? trackArtColors.primary : Colours.m3Colors.m3Primary
    readonly property bool  lyricsVisible: Players.active !== null && Configs.mediaPlayer.showLyrics && Lyrics.lines.length > 0

    property var            trackArtColors: TrackArt.colors

    Layout.fillHeight: Players.active !== null
    Layout.fillWidth: true
    spacing: Appearance.spacing.normal
    visible: Players.active !== null
    onLyricsVisibleChanged: {
        if (lyricsVisible)
            Lyrics.syncPlayback();
    }

    Item {
        Layout.fillWidth: true
        Layout.maximumHeight: 150
        Layout.minimumHeight: 150
        Layout.preferredHeight: 150
        implicitHeight: 150

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
            }
        }
    }

    Item {
        id: lyricsContainer

        Layout.fillHeight: true
        Layout.fillWidth: true

        StyledRect {
            id: lyricsCard

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            clip: true
            color: Colours.m3Colors.m3SurfaceContainer
            height: root.lyricsVisible ? parent.height : 0
            opacity: root.lyricsVisible ? 1 : 0
            radius: Appearance.rounding.small
            visible: opacity > 0
            Behavior on height {
                NAnim {
                    duration: Appearance.animations.durations.normal
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }
            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            LyricsView {
                id: lyricsView

                anchors {
                    left: parent.left
                    margins: Appearance.margin.normal
                    right: parent.right
                    top: parent.top
                }

                active: GlobalStates.isQuickSettingsOpen && root.lyricsVisible
                activeColor: root.accentColor
                activeFontSize: Appearance.fonts.size.large
                height: Math.max(0, lyricsContainer.height - Appearance.margin.normal * 2)
                horizontalAlignment: Text.AlignHCenter
                inactiveColor: Colours.m3Colors.m3OnSurface
                inactiveFontSize: Appearance.fonts.size.normal
                raised: false
                spacing: Appearance.spacing.small
                Component.onCompleted: Lyrics.syncPlayback()
            }
        }
    }
}
