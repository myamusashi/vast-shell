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

    readonly property color accentColor: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.primary : Colours.m3Colors.m3Primary
    readonly property bool  lyricsVisible: Players.active !== null && Configs.mediaPlayer.showLyrics && Lyrics.lines.length > 0
    readonly property color surfaceTextColor: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onSurface : Colours.m3Colors.m3OnSurface

    property var            trackArtColors: TrackArt.colors

    Layout.fillHeight: lyricsVisible
    Layout.fillWidth: true
    spacing: Appearance.spacing.normal
    visible: Players.active !== null

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

    StyledRect {
        id: lyricsCard

        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.minimumHeight: 120
        clip: true
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.small
        visible: root.lyricsVisible

        Loader {
            id: lyricsLoader

            active: root.lyricsVisible
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            asynchronous: false
            sourceComponent: LyricsView {
                id: lyricsView

                active: GlobalStates.isQuickSettingsOpen && root.lyricsVisible
                activeColor: root.accentColor
                activeFontSize: Appearance.fonts.size.large
                horizontalAlignment: Text.AlignHCenter
                inactiveColor: Qt.alpha(root.surfaceTextColor, 0.45)
                inactiveFontSize: Appearance.fonts.size.normal
                raised: false
                spacing: Appearance.spacing.small
                Component.onCompleted: {
                    Lyrics.syncPlayback();
                    if (Lyrics.currentLineIndex < 0)
                        lyricsView.listView.positionViewAtBeginning();
                    else
                        lyricsView.listView.positionViewAtIndex(Lyrics.currentLineIndex, ListView.Center);
                }
            }
        }
    }
}
