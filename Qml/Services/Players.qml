pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import qs.Core.Configs

Singleton {
    id: root

    readonly property MprisPlayer       active: players[index] ?? null
    readonly property int               index: {
        const followed = Configs.mediaPlayer.autoSwitchActivePlayer && root.playingIndex >= 0 ? root.playingIndex : root.manualIndex;
        return followed >= 0 && followed < root.players.length ? followed : 0;
    }
    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property int               playingIndex: {
        const list = root.players;
        for (let i = 0; i < list.length; i++)
            if (list[i].playbackState === MprisPlaybackState.Playing)
                return i;

        for (let i = 0; i < list.length; i++)
            if (list[i].playbackState === MprisPlaybackState.Paused)
                return i;

        return -1;
    }

    property int                        manualIndex: 0

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
