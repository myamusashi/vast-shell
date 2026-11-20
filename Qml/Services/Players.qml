pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import qs.Core.Configs

Singleton {
    id: root

    readonly property MprisPlayer       active: players[index] ?? null
    readonly property int               index: root.manualIndex >= 0 && root.manualIndex < root.players.length ? root.manualIndex : 0
    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property int               playingIndex: {
        const list = root.players;
        for (let i = 0; i < list.length; i++)
            if (list[i].playbackState === MprisPlaybackState.Playing)
                return i;

        return -1;
    }

    property int                        manualIndex: 0

    function                            boundedPosition(player: MprisPlayer): real {
        if (!player)
            return 0;
        const position = player.position;
        if (player.length <= 0 || position <= player.length)
            return Math.max(position, 0);

        // Some players never report a seek when the track restarts, so the position keeps growing.
        return player.loopState === MprisLoopState.Track ? position % player.length : player.length;
    }

    function                            syncActivePlayer(): void {
        if (Configs.mediaPlayer.autoSwitchActivePlayer && root.playingIndex >= 0)
            root.manualIndex = root.playingIndex;
    }

    Component.onCompleted: root.syncActivePlayer()

    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property int         index
            required property MprisPlayer modelData

            function                      onPlaybackStateChanged() {
                if (!Configs.mediaPlayer.autoSwitchActivePlayer)
                    return;

                if (modelData.playbackState === MprisPlaybackState.Playing)
                    root.manualIndex = index;
                else if (index === root.manualIndex && root.playingIndex >= 0)
                    root.manualIndex = root.playingIndex;
            }

            Component.onCompleted: {
                if (Configs.mediaPlayer.autoSwitchActivePlayer && modelData.playbackState === MprisPlaybackState.Playing)
                    root.manualIndex = index;
            }
            target: modelData
        }
    }

    Connections {

        function onAutoSwitchActivePlayerChanged() {
            root.syncActivePlayer();
        }

        target: Configs.mediaPlayer
    }

    IpcHandler {

        function list(): string {
            const playerSummaries = [];
            const players         = root.players;
            for (let i = 0; i < players.length; i++) {
                const player = players[i];
                playerSummaries.push({
                    identity: player.identity,
                    trackTitle: player.trackTitle,
                    trackArtist: player.trackArtist,
                    playbackStatus: player.playbackStatus,
                    volume: player.volume,
                    status: player.isPlaying
                });
            }
            return JSON.stringify(playerSummaries);
        }

        function next(): void {
            root.active?.next();
        }

        function previous(): void {
            root.active?.previous();
        }

        function status(): bool {
            return root.active?.isPlaying;
        }

        function stop(): void {
            root.active?.stop();
        }

        function togglePlaying(): void {
            root.active?.togglePlaying();
        }

        target: "mpris"
    }
}
