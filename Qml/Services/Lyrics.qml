pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Vast.Lyrics

import qs.Core.Configs
import qs.Core.States
import qs.Services

Singleton {
    id: root

    readonly property int  currentLineIndex: LyricsProvider.currentLineIndex
    readonly property real driftToleranceSeconds: 0.06
    readonly property var  lines: LyricsProvider.lines
    readonly property bool playing: LyricsProvider.playing
    readonly property real positionMs: internal.positionMs
    readonly property int  positionRefreshIntervalMs: 100
    readonly property bool synced: LyricsProvider.synced
    readonly property var  wordLines: LyricsProvider.wordLines

    property real          previousPositionSeconds: 0
    property real          syncedPositionSeconds: 0
    property real          syncedTimestampMilliseconds: 0

    signal                 playbackSynced

    function               currentPositionMs(): real {
        return LyricsProvider.currentPositionMs();
    }

    function               loadActiveTrack(): void {
        const player  = Players.active;
        const nextKey = root.trackKeyFor(player);
        if (!nextKey) {
            if (internal.loadedTrackKey !== "") {
                internal.loadedTrackKey = "";
                internal.loadedPlayer   = null;
                LyricsProvider.clear();
                root.resetSyncTracking(0);
            }
            return;
        }
        if (nextKey === internal.loadedTrackKey) {
            if (internal.loadedPlayer !== player) {
                internal.loadedPlayer = player;
                root.syncPlayback();
            }
            return;
        }
        internal.loadedTrackKey = nextKey;
        internal.loadedPlayer   = player;
        LyricsProvider.fetch(player.trackTitle, player.trackArtist, player.length);
        root.syncPlayback();
    }

    function               refreshPosition(): void {
        internal.positionMs = LyricsProvider.currentPositionMs();
    }

    function               resetSyncTracking(positionSeconds: real): void {
        root.previousPositionSeconds     = positionSeconds;
        root.syncedPositionSeconds       = positionSeconds;
        root.syncedTimestampMilliseconds = Date.now();
    }

    // Detects unannounced seeks, drift, and loop restarts against the scheduler's monotonic position.
    function               resyncIfDrifted(): void {
        const player = Players.active;
        if (!player?.trackTitle)
            return;
        const position = Players.boundedPosition(player);
        if (!player.isPlaying) {
            if (Math.abs(position - root.syncedPositionSeconds) > 0.05)
                root.syncPlayback();
            else
                root.previousPositionSeconds = position;
            return;
        }
        const expectedPosition = (LyricsProvider.currentPositionMs() - LyricsProvider.offsetMs) / 1000.0;
        const positionMoved    = Math.abs(position - root.previousPositionSeconds) >= 0.001;
        // Skip unchanged ticks from players with coarse D-Bus updates unless stalled > 1.2s.
        if (!positionMoved && Math.abs(position - expectedPosition) <= 1.2)
            return;
        const jumpedBackward = position + 0.2 < root.previousPositionSeconds;
        const drifted        = Math.abs(position - expectedPosition) > root.driftToleranceSeconds;
        if (jumpedBackward || drifted) {
            root.syncPlayback();
            return;
        }
        root.previousPositionSeconds = position;
    }

    function               setPositionConsumerActive(consumer: var, active: bool): void {
        const consumers = internal.activeConsumers;
        const index     = consumers.indexOf(consumer);
        if (active && index < 0) {
            internal.activeConsumers = consumers.concat([consumer]);
            if (consumers.length === 0)
                root.refreshPosition();
        } else if (!active && index >= 0) {
            internal.activeConsumers = consumers.filter(item => item !== consumer);
        }
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

    function               trackKeyFor(player: MprisPlayer): string {
        if (!player?.trackTitle)
            return "";
        return `${player.trackTitle}\0${player.trackArtist ?? ""}\0${Math.round(player.length ?? 0)}`;
    }

    Component.onCompleted: {
        if (!Players.active?.trackTitle)
            return;
        Qt.callLater(() => root.loadActiveTrack());
    }

    QtObject {
        id: internal

        property var         activeConsumers: []
        property MprisPlayer loadedPlayer: null
        property string      loadedTrackKey: ""
        property real        positionMs: LyricsProvider.currentPositionMs()
    }

    Binding {
        property: "offsetMs"
        target: LyricsProvider
        value: Configs.mediaPlayer.lyricsOffsetMs
    }

    FrameAnimation {
        running: internal.activeConsumers.length > 0 && root.playing && root.synced
        onTriggered: root.refreshPosition()
    }

    Connections {

        function onCurrentLineIndexChanged() {
            root.refreshPosition();
        }

        function onLyricsChanged() {
            const justLoaded = (Date.now() - root.syncedTimestampMilliseconds) < 500 && root.syncedPositionSeconds < 1.0;
            if (LyricsProvider.synced && !justLoaded)
                root.syncPlayback();
            else
                root.refreshPosition();
        }

        function onOffsetMsChanged() {
            root.refreshPosition();
        }

        function onPlaybackSynced() {
            root.refreshPosition();
            root.playbackSynced();
        }

        target: LyricsProvider
    }

    Connections {

        function onActiveChanged() {
            root.loadActiveTrack();
        }

        target: Players
    }

    Connections {

        function onPlaybackStateChanged() {
            const player = Players.active;
            if (!player)
                return;
            if (player.playbackState === MprisPlaybackState.Stopped) {
                internal.loadedTrackKey = "";
                internal.loadedPlayer   = null;
                LyricsProvider.clear();
                root.resetSyncTracking(0);
                return;
            }
            if (internal.loadedTrackKey === "" && player.trackTitle)
                root.loadActiveTrack();
            else
                root.syncPlayback();
        }

        function onPositionChanged() {
            root.resyncIfDrifted();
        }

        function onPostTrackChanged() {
            const player = Players.active;
            if (!player)
                return;
            const nextKey      = root.trackKeyFor(player);
            const playbackRate = player.rate > 0 ? player.rate : 1.0;
            if (!nextKey) {
                internal.loadedTrackKey = "";
                internal.loadedPlayer   = null;
                LyricsProvider.clear();
                root.resetSyncTracking(0);
                return;
            }
            if (nextKey === internal.loadedTrackKey && internal.loadedPlayer === player) {
                const justLoaded = (Date.now() - root.syncedTimestampMilliseconds) < 500 && root.syncedPositionSeconds < 1.0;
                if (!justLoaded) {
                    LyricsProvider.setPlayback(0, playbackRate, player.isPlaying);
                    root.resetSyncTracking(0);
                }
                return;
            }
            internal.loadedTrackKey = nextKey;
            internal.loadedPlayer   = player;
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
        interval: root.positionRefreshIntervalMs
        repeat: true
        running: (Players.active?.isPlaying ?? false) && root.synced
        onTriggered: Players.active.positionChanged()
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
