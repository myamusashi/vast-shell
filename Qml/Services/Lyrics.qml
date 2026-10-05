pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Vast.Lyrics

import qs.Core.States
import qs.Services

Singleton {
    id: root

    readonly property int currentLineIndex: LyricsProvider.currentLineIndex
    readonly property real currentWordDuration: LyricsProvider.currentWordDuration
    readonly property int currentWordIndex: LyricsProvider.currentWordIndex
    readonly property var lines: LyricsProvider.lines
    property var offsets: ({})
    readonly property int state: LyricsProvider.state
    readonly property bool synced: LyricsProvider.synced
    property bool trackJustChanged: false
    readonly property var wordLines: LyricsProvider.wordLines
    readonly property bool wordSynced: LyricsProvider.wordSynced

    Component.onCompleted: {
        const p = Players.active;
        if (!p?.trackTitle)
            return;
        Qt.callLater(() => {
            LyricsProvider.fetch(p.trackTitle, p.trackArtist, p.length);
            LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
        });
    }

    Connections {

        // re-anchor so dead-reckoning stays accurate
        function onPlaybackStateChanged() {
            const p = Players.active;
            if (!p)
                return;
            if (p.playbackState === MprisPlaybackState.Stopped) {
                LyricsProvider.clear();
                return;
            }
            LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
        }
        function onPostTrackChanged() {
            const p = Players.active;
            if (!p)
                return;
            LyricsProvider.clear();
            LyricsProvider.setPlayback(0, p.rate, p.isPlaying);
            LyricsProvider.fetch(p.trackTitle, p.trackArtist, p.length);
        }

        target: Players.active
    }
    Connections {
        function onIsQuickSettingsOpenChanged() {
            if (!GlobalStates.isQuickSettingsOpen)
                return;
            const p = Players.active;
            if (!p?.trackTitle)
                return;
            LyricsProvider.setPlayback(p.position, p.rate, p.isPlaying);
        }

        target: GlobalStates
    }
}
