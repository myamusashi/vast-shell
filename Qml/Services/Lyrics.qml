pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Vast.Lyrics

import qs.Core.States
import qs.Services

Singleton {
    id: root

    readonly property int  currentLineIndex: LyricsProvider.currentLineIndex
    readonly property real currentWordDuration: LyricsProvider.currentWordDuration
    readonly property int  currentWordIndex: LyricsProvider.currentWordIndex
    readonly property var  lines: LyricsProvider.lines
    readonly property int  state: LyricsProvider.state
    readonly property bool synced: LyricsProvider.synced
    readonly property var  wordLines: LyricsProvider.wordLines
    readonly property bool wordSynced: LyricsProvider.wordSynced

    property var           offsets: ({})
    property real          previousPositionSeconds: 0
    property real          syncedPositionSeconds: 0
    property real          syncedTimestampMilliseconds: 0
    property bool          trackJustChanged: false

    function               loadActiveTrack(): void {
        const player = Players.active;
        if (!player?.trackTitle) {
            LyricsProvider.clear();
            root.resetSyncTracking(0);
            return;
        }
        LyricsProvider.fetch(player.trackTitle, player.trackArtist, player.length);
        root.syncPlayback();
    }

    function               resetSyncTracking(positionSeconds: real): void {
        root.previousPositionSeconds     = positionSeconds;
        root.syncedPositionSeconds       = positionSeconds;
        root.syncedTimestampMilliseconds = Date.now();
    }

    function               syncPlayback(): void {
        const player = Players.active;
        if (!player)
            return;
        const position     = Players.boundedPosition(player);
        const playbackRate = player.rate > 0 ? player.rate : 1.0;
        LyricsProvider.setPlayback(position, playbackRate, player.isPlaying);
        root.resetSyncTracking(position);
    }

    // Detects unannounced seeks, drift, and loop restarts against the last anchored scheduler position.
    function               resyncIfDrifted(): void {
        const player = Players.active;
        if (!player?.trackTitle)
            return;
        const position = Players.boundedPosition(player);
        if (!player.isPlaying) {
            if (Math.abs(position - root.syncedPositionSeconds) > 0.1)
                root.syncPlayback();
            else
                root.previousPositionSeconds = position;
            return;
        }
        const playbackRate     = player.rate > 0 ? player.rate : 1.0;
        const elapsedSeconds   = (Date.now() - root.syncedTimestampMilliseconds) / 1000 * playbackRate;
        const expectedPosition = root.syncedPositionSeconds + elapsedSeconds;
        const jumpedBackward   = position + 0.2 < root.previousPositionSeconds;
        const drifted          = Math.abs(position - expectedPosition) > 1.0;
        if (jumpedBackward || drifted) {
            root.syncPlayback();
            return;
        }
        root.previousPositionSeconds = position;
    }

    Component.onCompleted: {
        if (!Players.active?.trackTitle)
            return;
        Qt.callLater(() => root.loadActiveTrack());
    }

    Connections {

        function onActiveChanged() {
            root.loadActiveTrack();
        }

        target: Players
    }

    Connections {

        // re-anchor so dead-reckoning stays accurate

        function onPlaybackStateChanged() {
            const player = Players.active;
            if (!player)
                return;
            if (player.playbackState === MprisPlaybackState.Stopped) {
                LyricsProvider.clear();
                root.resetSyncTracking(0);
                return;
            }
            root.syncPlayback();
        }

        function onPositionChanged() {
            root.resyncIfDrifted();
        }

        function onPostTrackChanged() {
            const player = Players.active;
            if (!player)
                return;
            const playbackRate = player.rate > 0 ? player.rate : 1.0;
            LyricsProvider.clear();
            LyricsProvider.setPlayback(0, playbackRate, player.isPlaying);
            root.resetSyncTracking(0);
            LyricsProvider.fetch(player.trackTitle, player.trackArtist, player.length);
        }

        function onRateChanged() {
            root.syncPlayback();
        }

        target: Players.active
    }

    Timer {
        interval: 500
        repeat: true
        running: Players.active?.isPlaying ?? false
        onTriggered: root.resyncIfDrifted()
    }

    Connections {

        function onIsQuickSettingsOpenChanged() {
            if (!GlobalStates.isQuickSettingsOpen)
                return;
            if (!Players.active?.trackTitle)
                return;
            root.syncPlayback();
        }

        target: GlobalStates
    }
}
